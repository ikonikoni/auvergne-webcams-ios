Pod::Spec.new do |s|
  s.name         = "Siren"
  s.version      = "2.0.4"
  s.summary      = "Notify users when a new version of your iOS app is available, and prompt them with the App Store link.."

  s.description  = <<-DESC
Siren is checks a user’s currently installed version of your iOS app against the version that is currently available in the App Store.
                   DESC

  s.homepage     = "https://github.com/ArtSabintsev/Siren"
  s.license      = "MIT"
  s.authors      = { "Arthur Ariel Sabintsev" => "arthur@sabintsev.com", "Aaron Brager" => "getaaron@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/ArtSabintsev/Siren.git", :tag => s.version.to_s }
  s.source_files = 'Sources/*.swift'
  s.resources    = 'Sources/Siren.bundle'
  s.requires_arc = true

end
