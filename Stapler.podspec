Pod::Spec.new do |s|
  s.name             = 'Stapler'
  s.version          = '0.2'
  s.summary          = 'Pagination handling made easy'
 
  s.description      = <<-DESC
Stapler is a Swift micro framework for iOS that encapsulates all the logic for fetching and refreshing paginated data. Stapler performs necessary backend requests and provides you with a ready-to-bind-to-UI reactive data source.
                       DESC
 
  s.homepage         = 'https://github.com/neekeetab/Stapler'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Nikita Belousov' => 'neekeetab@gmail.com' }
  s.source           = { :git => 'https://github.com/neekeetab/Stapler.git', :tag => "#{s.version}" }
 
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/*.{swift}'
  s.dependency 'ReactiveCocoa'
 
end
