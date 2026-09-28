# Adds the AudioKiddoWidget WidgetKit extension to ios/Runner.xcodeproj (idempotent).
# Run with the xcodeproj gem that ships with CocoaPods:
#   GEM_HOME="$(brew --prefix cocoapods)/libexec" "$(brew --prefix ruby)/bin/ruby" tool/add_ios_widget.rb
require 'xcodeproj'

root = File.expand_path('../app/ios', __dir__)
project = Xcodeproj::Project.open(File.join(root, 'Runner.xcodeproj'))
name = 'AudioKiddoWidget'

if (existing = project.targets.find { |t| t.name == name })
  # Re-attach Flutter's configs (version numbers) on an existing target.
  existing.build_configurations.each do |config|
    file = config.name == 'Debug' ? 'Debug.xcconfig' : 'Release.xcconfig'
    config.base_configuration_reference = project.files.find { |f| f.path.to_s.end_with?(file) }
  end
  project.save
  puts "#{name} already in the project; configs refreshed"
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
widget = project.new_target(:app_extension, name, :ios, '15.0', project.products_group, :swift)

group = project.main_group.new_group(name, name)
source = group.new_reference('AudioKiddoWidget.swift')
group.new_reference('Info.plist')
widget.add_file_references([source])
%w[WidgetKit SwiftUI].each do |framework|
  ref = project.frameworks_group.new_reference("System/Library/Frameworks/#{framework}.framework", :sdk_root)
  widget.frameworks_build_phase.add_file_reference(ref, true)
end

# Flutter's configs give the extension the app's version and build number.
xcconfig = ->(file) { project.files.find { |f| f.path.to_s.end_with?(file) } }
base = {
  'Debug' => xcconfig.call('Debug.xcconfig'),
  'Release' => xcconfig.call('Release.xcconfig'),
  'Profile' => xcconfig.call('Release.xcconfig'),
}
unless widget.build_configurations.any? { |c| c.name == 'Profile' }
  profile = widget.add_build_configuration('Profile', :release)
  profile.build_settings.merge!(widget.build_configurations.find { |c| c.name == 'Release' }.build_settings)
end
widget.build_configurations.each do |config|
  config.base_configuration_reference = base[config.name]
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => 'pl.audiokiddo.app.widget',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'INFOPLIST_FILE' => "#{name}/Info.plist",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.0',
    'CODE_SIGN_STYLE' => 'Automatic',
    'SKIP_INSTALL' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
  )
  team = runner.build_configurations.find { |c| c.name == config.name }&.build_settings&.[]('DEVELOPMENT_TEAM')
  config.build_settings['DEVELOPMENT_TEAM'] = team if team
end

# Embed the extension in the app. The copy phase must run before Flutter's script phases
# ("Thin Binary"), otherwise Xcode reports a dependency cycle.
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.build_phases.delete(embed)
first_script = runner.build_phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && p.name.to_s.include?('Thin Binary') }
runner.build_phases.insert(first_script || runner.build_phases.length, embed)

project.save
puts "Added #{name}"
