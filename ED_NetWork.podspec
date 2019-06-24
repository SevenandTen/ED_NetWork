

Pod::Spec.new do |s|

 

  s.name         = "ED_NetWork"
  s.version      = "0.0.1"
  s.summary      = "A  test ED_NetWork"


  s.description  = <<-DESC
		网路框架 基于NSURLSession 封装的网路框架，支持代理 和 block
                   DESC

  s.homepage     = "https://github.com/SevenandTen/ED_NetWork"



  s.license      = "MIT"
 



  s.author             = { "shiqiqi" => "a380814015@qq.com" }

 
 

  s.platform     = :ios ,"8.0"



  s.source       = { :git => "https://github.com/SevenandTen/ED_NetWork.git", :tag => "#{s.version}" }



  s.source_files  = "ED_NetWork", "ED_NetWork/*.{h,m}"
 

end
