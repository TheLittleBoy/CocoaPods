module Pod
  class Installer

    # Controller class responsible of creating and configuring the static
    # library target in Pods project. It also creates the support file needed
    # by the target.
    #
    class TargetInstaller

      # @return [Sandbox] sandbox the sandbox where the support files should
      #         be generated.
      #
      attr_reader :sandbox

      # @return [Library] The library whose target needs to be generated.
      #
      attr_reader :library

      # @param  [Project] project @see project
      # @param  [Library] library @see library
      #
      def initialize(sandbox, library)
        @sandbox = sandbox
        @library = library
      end

      # Creates the target in the Pods project and the relative support files.
      #
      # @return [void]
      #
      def install!
        UI.message "- Installing target `#{library.name}` #{library.platform}" do
          add_target
          add_files_to_build_phases
          create_suport_files_group

          create_xcconfig_file
          create_target_header
          create_prefix_header
          create_bridge_support_file
          create_copy_resources_script
          create_acknowledgements
          create_dummy_source
        end
      end

      #-----------------------------------------------------------------------#

      private

      # @!group Installation steps

      # Adds the target for the library to the Pods project with the
      # appropriate build configurations.
      #
      # @note   The `PODS_HEADERS_SEARCH_PATHS` overrides the xcconfig.
      #
      # @todo   Add integration test for build configurations and don't add the
      #         build configurations to the project if they are not needed.
      #
      # @return [void]
      #
      def add_target
        name = library.label
        platform = library.platform.name
        deployment_target = library.platform.deployment_target.to_s
        @target = project.new_target(:static_library, name, platform, deployment_target)

        settings = {}
        if library.platform.requires_legacy_ios_archs?
          settings['ARCHS'] = "armv6 armv7"
        end
        if target_definition.inhibit_all_warnings?
          settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        end

        @target.build_settings('Debug').merge!(settings)
        @target.build_settings('Release').merge!(settings)

        library.user_build_configurations.each do |lib_name, type|
          unless @target.build_configurations.map(&:name).include?(lib_name)
            build_config = project.new(Xcodeproj::Project::XCBuildConfiguration)
            build_config.name = lib_name
            settings = @target.build_settings(type.to_s.capitalize)
            build_config.build_settings = settings
            target.build_configurations << build_config
            project.build_configurations << build_config
          end
        end

        library.target = @target
      end

      ENABLE_OBJECT_USE_OBJC_FROM = {
        :ios => Version.new('6'),
        :osx => Version.new('10.8')
      }

      # Adds the build files of the pods to the target and adds a reference to
      # the frameworks of the Pods.
      #
      # @note   The Frameworks are used only for presentation purposes as the
      #         xcconfig is the authoritative source about their information.
      #
      # @return [void]
      #
      def add_files_to_build_phases
        UI.message "- Adding Build files" do
          library.file_accessors.each do |file_accessor|
            consumer = file_accessor.spec_consumer
            flags = compiler_flags_for_consumer(consumer)
            source_files = file_accessor.source_files
            file_refs = source_files.map { |sf| project.file_reference(sf) }
            target.add_file_references(file_refs, flags)

            file_accessor.spec_consumer.frameworks.each do |framework|
              project.add_system_framework(framework, target)
            end
          end
        end
      end

      # Creates the group that holds the references to the support files
      # generated by this installer.
      #
      # @return [void]
      #
      def create_suport_files_group
        name = target_definition.label
        @support_files_group = project.support_files_group.new_group(name)
      end

      #--------------------------------------#

      # Generates the contents of the xcconfig file and saves it to disk.
      #
      # @note   The `ALWAYS_SEARCH_USER_PATHS` flag is enabled to support
      #         libraries like `EmbedReader`.
      #
      # @return [void]
      #
      def create_xcconfig_file
        path = library.xcconfig_path
        UI.message "- Generating xcconfig file at #{UI.path(path)}" do
          gen = Generator::XCConfig.new(sandbox, spec_consumers, library.relative_pods_root)
          gen.set_arc_compatibility_flag = target_definition.podfile.set_arc_compatibility_flag?
          gen.save_as(path)
          library.xcconfig = gen.xcconfig
          xcconfig_file_ref = add_file_to_support_group(path)

          target.build_configurations.each do |c|
            c.base_configuration_reference = xcconfig_file_ref
            Generator::XCConfig.pods_project_settings.each do |key, value|
              c.build_settings[key] = value
            end
          end
        end
      end

      # Generates a header which allows to inspect at compile time the installed
      # pods and the installed specifications of a pod.
      #
      def create_target_header
        path = library.target_header_path
        UI.message "- Generating target header at #{UI.path(path)}" do
          generator = Generator::TargetHeader.new(library.specs)
          generator.save_as(path)
          add_file_to_support_group(path)
        end
      end

      # Creates a prefix header file which imports `UIKit` or `Cocoa` according
      # to the platform of the target. This file also include any prefix header
      # content reported by the specification of the pods.
      #
      # @return [void]
      #
      def create_prefix_header
        path = library.prefix_header_path
        UI.message "- Generating prefix header at #{UI.path(path)}" do
          generator = Generator::PrefixHeader.new(library.file_accessors, library.platform)
          generator.imports << library.target_header_path.basename
          generator.save_as(path)
          add_file_to_support_group(path)

          target.build_configurations.each do |c|
            relative_path = path.relative_path_from(sandbox.root)
            c.build_settings['GCC_PREFIX_HEADER'] = relative_path.to_s
          end
        end
      end

      # Generates the bridge support metadata if requested by the {Podfile}.
      #
      # @note   The bridge support metadata is added to the resources of the
      #         library because it is needed for environments interpreted at
      #         runtime.
      #
      # @return [void]
      #
      def create_bridge_support_file
        if target_definition.podfile.generate_bridge_support?
          path = library.bridge_support_path
          UI.message "- Generating BridgeSupport metadata at #{UI.path(path)}" do
            headers = target.headers_build_phase.files.map { |bf| sandbox.root + bf.file_ref.path }
            generator = Generator::BridgeSupport.new(headers)
            generator.save_as(path)
            add_file_to_support_group(path)
            @bridge_support_file = path.relative_path_from(sandbox.root)
          end
        end
      end

      # Creates a script that copies the resources to the bundle of the client
      # target.
      #
      # @note   The bridge support file needs to be created before the prefix
      #         header, otherwise it will not be added to the resources script.
      #
      # @return [void]
      #
      def create_copy_resources_script
        path = library.copy_resources_script_path
        UI.message "- Generating copy resources script at #{UI.path(path)}" do
          resources = library.file_accessors.map { |accessor| accessor.resources.flatten.map {|res| project.relativize(res)} }.flatten
          resources << bridge_support_file if bridge_support_file
          generator = Generator::CopyResourcesScript.new(resources)
          generator.save_as(path)
          add_file_to_support_group(path)
        end
      end

      # Generates the acknowledgement files (markdown and plist) for the target.
      #
      # @return [void]
      #
      def create_acknowledgements
        basepath = library.acknowledgements_basepath
        Generator::Acknowledgements.generators.each do |generator_class|
          path = generator_class.path_from_basepath(basepath)
          UI.message "- Generating acknowledgements at #{UI.path(path)}" do
            generator = generator_class.new(library.file_accessors)
            generator.save_as(path)
            add_file_to_support_group(path)
          end
        end
      end

      # Generates a dummy source file for each target so libraries that contain
      # only categories build.
      #
      # @return [void]
      #
      def create_dummy_source
        path = library.dummy_source_path
        UI.message "- Generating dummy source file at #{UI.path(path)}" do
          generator = Generator::DummySource.new(library.label)
          generator.save_as(path)
          file_reference = add_file_to_support_group(path)
          target.source_build_phase.add_file_reference(file_reference)
        end
      end

      #-----------------------------------------------------------------------#

      private

      # @return [PBXNativeTarget] the target generated by the installation
      #         process.
      #
      # @note   Generated by the {#add_target} step.
      #
      attr_reader :target

      # @!group Private helpers.

      # @return [Project] the Pods project of the sandbox.
      #
      def project
        sandbox.project
      end

      # @return [TargetDefinition] the target definition of the library.
      #
      def target_definition
        library.target_definition
      end

      # @return [Specification::Consumer] the consumer for the specifications.
      #
      def spec_consumers
         @spec_consumers ||= library.file_accessors.map(&:spec_consumer)
      end

      # @return [PBXGroup] the group where the file references to the support
      #         files should be stored.
      #
      attr_reader :support_files_group

      # @return [Pathname] the path of the bridge support file relative to the
      #         sandbox.
      #
      # @return [Nil] if no bridge support file was generated.
      #
      attr_reader :bridge_support_file

      # Adds a reference to the given file in the support group of this target.
      #
      # @param  [Pathname] path
      #         The path of the file to which the reference should be added.
      #
      # @return [PBXFileReference] the file reference of the added file.
      #
      def add_file_to_support_group(path)
        relative_path = path.relative_path_from(sandbox.root)
        support_files_group.new_file(relative_path)
      end

      # Returns the compiler flags for the source files of the given specification.
      #
      # The following behavior is regarding the `OS_OBJECT_USE_OBJC` flag. When
      # set to `0`, it will allow code to use `dispatch_release()` on >= iOS 6.0
      # and OS X 10.8.
      #
      # * New libraries that do *not* require ARC don???t need to care about this
      #   issue at all.
      #
      # * New libraries that *do* require ARC _and_ have a deployment target of
      #   >= iOS 6.0 or OS X 10.8:
      #
      #   These no longer use `dispatch_release()` and should *not* have the
      #   `OS_OBJECT_USE_OBJC` flag set to `0`.
      #
      #   **Note:** this means that these libraries *have* to specify the
      #             deployment target in order to function well.
      #
      # * New libraries that *do* require ARC, but have a deployment target of
      #   < iOS 6.0 or OS X 10.8:
      #
      #   These contain `dispatch_release()` calls and as such need the
      #   `OS_OBJECT_USE_OBJC` flag set to `1`.
      #
      #   **Note:** libraries that do *not* specify a platform version are
      #             assumed to have a deployment target of < iOS 6.0 or OS X 10.8.
      #
      #  For more information, see: http://opensource.apple.com/source/libdispatch/libdispatch-228.18/os/object.h
      #
      # @param  [Specification::Consumer] consumer
      #         The consumer for the specification for which the compiler flags
      #         are needed.
      #
      # @return [String] The compiler flags.
      #
      def compiler_flags_for_consumer(consumer)
        flags = consumer.compiler_flags.dup
        if consumer.requires_arc
          flags << '-fobjc-arc'
          platform_name = consumer.platform_name
          spec_deployment_target = consumer.spec.deployment_target(platform_name)
          if spec_deployment_target.nil? || Version.new(spec_deployment_target) < ENABLE_OBJECT_USE_OBJC_FROM[platform_name]
            flags << '-DOS_OBJECT_USE_OBJC=0'
          end
        end
        flags = flags * " "
      end

      #-----------------------------------------------------------------------#

    end
  end
end

