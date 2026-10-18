platform :ios, '17.0'
use_frameworks!

target 'Masarify' do
  # Smooth vector animations for hero / empty / success states
  pod 'lottie-ios', '~> 4.5'

  # Better keyboard handling on expense & budget forms
  pod 'IQKeyboardManagerSwift', '~> 7.0'

  # Lightweight success / error toasts after save
  pod 'AlertToast', '~> 1.3'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
