require File.expand_path('../../../spec_helper', __FILE__)

module ProjectSpecs
  describe AbstractTarget do
    describe 'In general' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
      end

      it 'returns the product name, which is the name of the binary (minus prefix/suffix)' do
        @target.name.should == 'Pods'
        @target.product_name.should == 'Pods'
      end
    end

    #----------------------------------------#

    describe 'Helpers' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
      end

      describe '#common_resolved_build_setting' do
        it 'returns the resolved build setting for the given key as indicated in the target build configuration' do
          @project.build_configuration_list.set_setting('ARCHS', nil)
          @target.build_configuration_list.set_setting('ARCHS', 'VALID_ARCHS')
          @target.resolved_build_setting('ARCHS').should == { 'Release' => 'VALID_ARCHS', 'Debug' => 'VALID_ARCHS' }
        end

        it 'returns the resolved build setting for the given key as indicated in the project build configuration' do
          @project.build_configuration_list.set_setting('ARCHS', 'VALID_ARCHS')
          @target.build_configuration_list.set_setting('ARCHS', nil)
          @target.resolved_build_setting('ARCHS').should == { 'Release' => 'VALID_ARCHS', 'Debug' => 'VALID_ARCHS' }
        end

        it 'overrides the project settings with the target ones' do
          @project.build_configuration_list.set_setting('ARCHS', 'VALID_ARCHS')
          @target.build_configuration_list.set_setting('ARCHS', 'arm64')
          @target.resolved_build_setting('ARCHS').should == { 'Release' => 'arm64', 'Debug' => 'arm64' }
        end
      end

      #----------------------------------------#

      describe '#common_resolved_build_setting' do
        it 'returns the common resolved build setting for the given key as indicated in the target build configuration' do
          @project.build_configuration_list.set_setting('ARCHS', nil)
          @target.build_configuration_list.set_setting('ARCHS', 'VALID_ARCHS')
          @target.common_resolved_build_setting('ARCHS').should == 'VALID_ARCHS'
        end

        it 'returns the common resolved build setting for the given key as indicated in the project build configuration' do
          @project.build_configuration_list.set_setting('ARCHS', 'VALID_ARCHS')
          @target.build_configuration_list.set_setting('ARCHS', nil)
          @target.common_resolved_build_setting('ARCHS').should == 'VALID_ARCHS'
        end

        it 'raises if the build setting has multiple values across the build configurations' do
          @target.build_configuration_list.build_configurations.first.build_settings['ARCHS'] = 'arm64'
          @target.build_configuration_list.build_configurations.last.build_settings['ARCHS'] = 'VALID_ARCHS'
          should.raise do
            @target.common_resolved_build_setting('ARCHS')
          end.message.should.match /multiple values/
        end

        it 'ignores nil values when determining if an unique value exists' do
          @target.build_configuration_list.build_configurations.first.build_settings['ARCHS'] = nil
          @target.build_configuration_list.build_configurations.last.build_settings['ARCHS'] = 'VALID_ARCHS'
          should.not.raise do
            @target.common_resolved_build_setting('ARCHS')
          end
        end
      end

      #----------------------------------------#

      it 'returns the SDK specified in its build configuration' do
        @project.build_configuration_list.set_setting('SDKROOT', nil)
        @target.build_configuration_list.set_setting('SDKROOT', 'iphoneos')
        @target.sdk.should == 'iphoneos'
      end

      it 'returns the SDK of the project if one is not specified in the build configurations' do
        @project.build_configuration_list.set_setting('SDKROOT', 'iphoneos')
        @target.build_configuration_list.set_setting('SDKROOT', nil)
        @target.sdk.should == 'iphoneos'
      end

      it 'returns the platform name' do
        @project.new_target(:static_library, 'Pods', :ios).platform_name.should == :ios
        @project.new_target(:static_library, 'Pods', :osx).platform_name.should == :osx
      end

      it 'returns the SDK version' do
        @project.new_target(:static_library, 'Pods', :ios).sdk_version.should.nil?
        @project.new_target(:static_library, 'Pods', :osx).sdk_version.should.nil?

        t1 = @project.new_target(:static_library, 'Pods', :ios)
        t1.build_configuration_list.set_setting('SDKROOT', 'iphoneos7.0')
        t1.sdk_version.should == '7.0'

        t2 = @project.new_target(:static_library, 'Pods', :osx)
        t2.build_configuration_list.set_setting('SDKROOT', 'macosx10.8')
        t2.sdk_version.should == '10.8'
      end

      describe 'returns the deployment target specified in its build configuration' do
        it 'works for iOS' do
          @project.build_configuration_list.set_setting('IPHONEOS_DEPLOYMENT_TARGET', nil)
          @project.new_target(:static_library, 'Pods', :ios, '4.3').deployment_target.should == '4.3'
        end

        it 'works for OSX' do
          @project.build_configuration_list.set_setting('MACOSX_DEPLOYMENT_TARGET', nil)
          @project.new_target(:static_library, 'Pods', :osx, '10.7').deployment_target.should == '10.7'
        end
      end

      describe 'returns the deployment target of the project build configuration' do
        it 'works for iOS' do
          @project.build_configuration_list.set_setting('IPHONEOS_DEPLOYMENT_TARGET', '4.3')
          ios_target = @project.new_target(:static_library, 'Pods', :ios)
          ios_target.build_configurations.first.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = nil
          ios_target.deployment_target.should == '4.3'
        end

        it 'works for OSX' do
          @project.build_configuration_list.set_setting('MACOSX_DEPLOYMENT_TARGET', '10.7')
          osx_target = @project.new_target(:static_library, 'Pods', :osx)
          osx_target.build_configurations.first.build_settings['MACOSX_DEPLOYMENT_TARGET'] = nil
          osx_target.deployment_target.should == '10.7'
        end
      end

      it 'returns the build configuration' do
        build_configurations = @target.build_configurations
        build_configurations.map(&:isa).uniq.should == ['XCBuildConfiguration']
        build_configurations.map(&:name).sort.should == %w(Debug Release)
      end

      #----------------------------------------#

      describe '#add_build_configuration' do
        it 'adds a new build configuration' do
          @target.add_build_configuration('App Store', :release)
          @target.build_configurations.map(&:name).sort.should == ['App Store', 'Debug', 'Release']
        end

        it "doesn't duplicate build configurations with existing names" do
          @target.add_build_configuration('App Store', :release)
          @target.add_build_configuration('App Store', :release)
          @target.build_configurations.map(&:name).grep('App Store').size.should == 1
        end

        it 'returns the new build configuration' do
          conf = @target.add_build_configuration('App Store', :release)
          conf.name.should == 'App Store'
        end

        it 'returns the existing build configuration' do
          conf_1 = @target.add_build_configuration('App Store', :release)
          conf_2 = @target.add_build_configuration('App Store', :release)
          conf_1.object_id.should == conf_2.object_id
        end
      end

      #----------------------------------------#

      it 'returns the build settings of the configuration with the given name' do
        @target.build_settings('Debug')['PRODUCT_NAME'].should == '$(TARGET_NAME)'
      end

      describe '#add_dependency' do
        extend SpecHelper::TemporaryDirectory

        it 'adds a dependency on another target' do
          dependency_target = @project.new_target(:static_library, 'Pods-SMCalloutView', :ios)
          @target.add_dependency(dependency_target)
          @target.dependencies.count.should == 1
          target_dependency = @target.dependencies.first
          target_dependency.target.should == dependency_target
          container_proxy = target_dependency.target_proxy
          container_proxy.container_portal.should == @project.root_object.uuid
          container_proxy.proxy_type.should == '1'
          container_proxy.remote_global_id_string.should == dependency_target.uuid
          container_proxy.remote_info.should == dependency_target.name
        end

        it 'adds a dependency on a target in a subproject' do
          path = fixture_path('Sample Project/ReferencedProject/ReferencedProject.xcodeproj')
          subproject = Xcodeproj::Project.open(path)
          dependency_target = subproject.targets.first
          subproject_file_reference = @project.main_group.new_file(path)
          @target.add_dependency(dependency_target)

          @target.dependencies.count.should == 1
          target_dependency = @target.dependencies.first
          target_dependency.target.should.be.nil

          container_proxy = target_dependency.target_proxy
          container_proxy.container_portal.should == subproject_file_reference.uuid
          container_proxy.remote_global_id_string.should == dependency_target.uuid

          # Regression test: Ensure that we can open the modified project
          # without attempting to initialize an object with an unknown UUID
          Xcodeproj::UI.stubs(:warn).never
          temp_path = temporary_directory + 'ProjectWithTargetDependencyToSubproject.xcodeproj'
          @project.save(temp_path)
          Xcodeproj::Project.open(temp_path)
        end

        it "doesn't add a dependency on a target in an unknown project" do
          unknown_project = Xcodeproj::Project.new('/other_project_dir/OtherProject.xcodeproj')
          dependency_target = unknown_project.new_target(:static_library, 'Pods-SMCalloutView', :ios)

          should.raise ArgumentError do
            @target.add_dependency(dependency_target)
          end.message.should.match /not this project/
        end

        it "doesn't duplicate dependencies" do
          dependency_target = @project.new_target(:static_library, 'Pods-SMCalloutView', :ios)
          @target.add_dependency(dependency_target)
          @target.add_dependency(dependency_target)
          @target.dependencies.count.should == 1
        end
      end

      describe '#dependency_for_target' do
        before do
          subproject_path = fixture_path('Sample Project/ReferencedProject/ReferencedProject.xcodeproj')
          @subproject = Xcodeproj::Project.open(subproject_path)

          project_path = fixture_path('Sample Project/ContainsSubproject/ContainsSubproject.xcodeproj')
          @project = Xcodeproj::Project.open(project_path)
        end

        it 'returns the dependency for targets from the current project' do
          @target = @project.targets.find { |t| t.name == 'ContainsSubprojectTests' }
          @target.dependency_for_target(@project.targets.first).should == @target.dependencies.first
        end

        it 'returns the dependency for targets from a subproject' do
          @target = @project.targets.first
          @target.dependency_for_target(@subproject.targets.first).should == @target.dependencies.first
        end
      end
    end

    #----------------------------------------#

    describe 'Build phases' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
        @target.build_phases << @project.new(PBXCopyFilesBuildPhase)
        @target.build_phases << @project.new(PBXShellScriptBuildPhase)
      end

      {
        :headers_build_phase       => PBXHeadersBuildPhase,
        :source_build_phase        => PBXSourcesBuildPhase,
        :frameworks_build_phase    => PBXFrameworksBuildPhase,
        :resources_build_phase     => PBXResourcesBuildPhase,
        :copy_files_build_phases   => PBXCopyFilesBuildPhase,
        :shell_script_build_phases => PBXShellScriptBuildPhase,
      }.each do |association_method, klass|
        it "returns an empty #{klass.isa}" do
          phase = @target.send(association_method)
          if phase.is_a? Array
            phase = phase.first
          end

          phase.should.be.instance_of klass
          if phase.is_a? PBXFrameworksBuildPhase
            phase.files.count.should == 1
          else
            phase.files.to_a.should == []
          end
        end
      end

      it 'returns the frameworks build phase' do
        @target.frameworks_build_phases.class.should == PBXFrameworksBuildPhase
      end

      it "creates a new 'copy files build phase'" do
        before = @target.copy_files_build_phases.count
        @target.new_copy_files_build_phase
        @target.copy_files_build_phases.count.should == before + 1
      end

      it "creates a new 'shell script build phase'" do
        before = @target.shell_script_build_phases.count
        @target.new_shell_script_build_phase
        @target.shell_script_build_phases.count.should == before + 1
      end
    end

    #----------------------------------------#

    describe 'System frameworks' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
        @target.frameworks_build_phase.clear
        @project.frameworks_group.clear
      end

      describe '#add_system_framework' do
        it 'adds a file reference for a system framework, in a dedicated subgroup of the Frameworks group' do
          @target.add_system_framework('QuartzCore')
          file = @project['Frameworks/iOS'].files.first
          file.path.should == 'Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.1.sdk/System/Library/Frameworks/QuartzCore.framework'
          file.source_tree.should == 'DEVELOPER_DIR'
        end

        it 'uses the sdk version of the target' do
          @target.build_configuration_list.set_setting('SDKROOT', 'iphoneos6.0')
          @target.add_system_framework('QuartzCore')
          file = @project['Frameworks/iOS'].files.first
          file.path.scan(/\d\.\d/).first.should == '6.0'
        end

        it 'uses the last known SDK version if none is specified in the target' do
          @target.build_configuration_list.set_setting('SDKROOT', 'iphoneos')
          @target.add_system_framework('QuartzCore')
          file = @project['Frameworks/iOS'].files.first
          file.path.scan(/\d\.\d/).first.should == Xcodeproj::Constants::LAST_KNOWN_IOS_SDK
        end

        it "doesn't duplicate references to a frameworks if one already exists" do
          @target.add_system_framework('QuartzCore')
          @target.add_system_framework('QuartzCore')
          @project['Frameworks/iOS'].files.count.should == 1
        end

        it 'adds the framework to the framework build phases' do
          @target.add_system_framework('QuartzCore')
          @target.frameworks_build_phase.file_display_names.should == ['QuartzCore.framework']
        end

        it "doesn't duplicate the frameworks in the build phases" do
          @target.add_system_framework('QuartzCore')
          @target.add_system_framework('QuartzCore')
          @target.frameworks_build_phase.files.count.should == 1
        end

        it 'can add multiple frameworks' do
          @target.add_system_frameworks(%w(CoreData QuartzCore))
          names = @target.frameworks_build_phase.file_display_names
          names.should == ['CoreData.framework', 'QuartzCore.framework']
        end
      end

      #----------------------------------------#

      describe '#add_system_library' do
        it 'adds a file reference for a system framework, to the Frameworks group' do
          @target.add_system_library('xml')
          file = @project['Frameworks'].files.first
          file.path.should == 'usr/lib/libxml.dylib'
          file.source_tree.should == 'SDKROOT'
        end

        it "doesn't duplicate references to a frameworks if one already exists" do
          @target.add_system_library('xml')
          @target.add_system_library('xml')
          @project.frameworks_group.files.count.should == 1
        end

        it 'adds the framework to the framework build phases' do
          @target.add_system_library('xml')
          @target.frameworks_build_phase.file_display_names.should == ['libxml.dylib']
        end

        it "doesn't duplicate the frameworks in the build phases" do
          @target.add_system_library('xml')
          @target.add_system_library('xml')
          @target.frameworks_build_phase.files.count.should == 1
        end

        it 'can add multiple libraries' do
          @target.add_system_libraries(%w(z xml))
          names = @target.frameworks_build_phase.file_display_names
          names.should == ['libz.dylib', 'libxml.dylib']
        end
      end
    end

    #----------------------------------------#

    describe 'AbstractObject Hooks' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
      end

      it 'returns the pretty print representation' do
        pretty_print = @target.pretty_print
        pretty_print['Pods']['Build Phases'].should == [
          { 'SourcesBuildPhase' => [] },
          { 'FrameworksBuildPhase' => ['Foundation.framework'] },
        ]
        build_configurations = pretty_print['Pods']['Build Configurations']
        build_configurations.map { |bf| bf.keys.first } .should == %w(Release Debug)
      end
    end
  end

  #---------------------------------------------------------------------------#

  describe PBXNativeTarget do
    describe 'In general' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
      end

      it 'returns the product name, which is the name of the binary (minus prefix/suffix)' do
        @target.name.should == 'Pods'
        @target.product_name.should == 'Pods'
      end

      it 'returns the product' do
        @target.product_reference.should.be.instance_of PBXFileReference
        @target.product_reference.path.should == 'libPods.a'
      end

      it 'returns that product type is a static library' do
        @target.product_type.should == 'com.apple.product-type.library.static'
      end

      it 'returns an empty list of dependencies and build rules' do
        @target.dependencies.to_a.should == []
        @target.build_rules.to_a.should == []
      end

      describe '#sort' do
        it 'can be sorted' do
          dep_2 = @project.new_target(:static_library, 'Dep_2', :ios)
          dep_1 = @project.new_target(:static_library, 'Dep_1', :ios)
          @target.add_dependency(dep_2)
          @target.add_dependency(dep_1)
          @target.sort
          @target.dependencies.map(&:display_name).should == %w(Dep_1 Dep_2)
        end

        it "doesn't sort the build phases" do
          @target.build_phases << @project.new(PBXSourcesBuildPhase)
          @target.build_phases << @project.new(PBXHeadersBuildPhase)
          @target.build_phases << @project.new(PBXSourcesBuildPhase)
          @target.sort
          @target.build_phases.map(&:isa).should == %w(PBXSourcesBuildPhase PBXFrameworksBuildPhase PBXSourcesBuildPhase PBXHeadersBuildPhase PBXSourcesBuildPhase)
        end
      end
    end

    #----------------------------------------#

    describe 'Helpers' do
      before do
        @target = @project.new_target(:static_library, 'Pods', :ios)
      end

      describe '#symbol_type' do
        it 'returns the symbol type' do
          @target.symbol_type.should == :static_library
        end

        it 'returns nil if the product type is unknown' do
          @target.stubs(:product_type => 'com.apple.product-type.new-stuff')
          @target.symbol_type.should.be.nil?
        end
      end

      it 'adds a list of source files to the target to the source build phase' do
        ref = @project.main_group.new_file('Class.m')
        @target.add_file_references([ref], '-fobjc-arc')
        build_files = @target.source_build_phase.files
        build_files.count.should == 1
        build_files.first.file_ref.path.should == 'Class.m'
        build_files.first.settings.should == { 'COMPILER_FLAGS' => '-fobjc-arc' }
      end

      it 'adds a list of header files to the target header build phases' do
        ref = @project.main_group.new_file('Class.h')
        @target.add_file_references([ref], '-fobjc-arc')
        build_files = @target.headers_build_phase.files
        build_files.count.should == 1
        build_files.first.file_ref.path.should == 'Class.h'
        build_files.first.settings.should.be.nil
      end

      it 'returns a list of header files to the target header build phases' do
        ref = @project.main_group.new_file('Class.h')
        new_build_files = @target.add_file_references([ref], '-fobjc-arc')
        build_files = @target.headers_build_phase.files
        new_build_files.should == build_files
      end

      it 'yields a list of header files to the target header build phases' do
        ref = @project.main_group.new_file('Class.h')
        build_files = @target.add_file_references([ref], '-fobjc-arc') do |build_file|
          build_file.should.be.an.instance_of?(PBXBuildFile)
          build_file.settings = { 'ATTRIBUTES' => ['Public'] }
        end
        build_files.first.settings.should == { 'ATTRIBUTES' => ['Public'] }
      end

      it 'adds a list of resources to the resources build phase' do
        ref = @project.main_group.new_file('Image.png')
        @target.add_resources([ref])
        build_files = @target.resources_build_phase.files
        build_files.count.should == 1
        build_files.first.file_ref.path.should == 'Image.png'
        build_files.first.settings.should.be.nil
      end
    end
  end

  #---------------------------------------------------------------------------#
end
