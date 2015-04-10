Pod::Spec.new do |s|
  
  s.name         = "FCGIKit"
  s.version      = "0.2.0"
  s.summary      = "A Cocoa framework for creating FCGI web applications."

  s.description  = <<-DESC

                   FCGIKit helps create self-contained web-applications that serve web content via webserver through the Fast-CGI protocol (http://www.fastcgi.com/).
                   The FCGI protocol implementation was written by Magnus Nordlander in 2011 (see https://github.com/fervo/FCGIKit).
                   
                   DESC

  s.homepage     = "http://github.com/thecatalinstan/FCGIKit"  

  s.license  = { :type => 'public domain', :text => <<-LICENSE

Public Domain License

The FCGIKit project is in the public domain.

The FCGI protocol implementation was written by Magnus Nordlander in 2011 (see https://github.com/fervo/FCGIKit)

Updated and maintained by Cătălin Stan.

                 LICENSE
               }

  s.author             = { "Cătălin Stan" => "catalin.stan@me.com" }
  s.social_media_url   = "http://twitter.com/catalinstan"

  s.osx.frameworks = 'CoreServices', 'Security'

  s.source       = { :git => "http://github.com/thecatalinstan/FCGIKit.git", :tag => "0.1.2" }

  s.source_files  = "Classes", "Classes/**/*.{h,m}"

 	s.osx.deployment_target = '10.8'
  s.osx.frameworks = 'CFNetwork', 'Foundation'
  
  s.requires_arc = true
	s.xcconfig = { "ENABLE_STRICT_OBJC_MSGSEND" => "NO" }
  s.dependency "CocoaAsyncSocket", "~> 7.4.0"

end
