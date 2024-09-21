import Foundation

let DefaultBaseURL = "https://api.unsplash.com"
let authorizeURLString = "https://unsplash.com/oauth/authorize"
let AccessKey = "YY_3VaSwj3Nc40rzgGRkT6lskWXQwf41jWouLeOq1mc"
let SecretKey = "onZ7lEXc1mrwN2yZ6vTWXO2r1SMBrt3L2pGdP_uCzek"
let RedirectURI = "urn:ietf:wg:oauth:2.0:oob"
let AccessScope = "public+read_user+write_likes"

struct AuthConfiguration {
    let access_Key: String
    let secret_Key: String
    let redirect_URI: String
    let access_Scope: String
    let default_Base_URL: String
    let authorize_URL_String: String
    
    static var standard: AuthConfiguration {
        return AuthConfiguration(accessKey: AccessKey,
                                 secretKey: SecretKey,
                                 redirectURI: RedirectURI,
                                 accessScope: AccessScope,
                                 authorizeURLString: authorizeURLString,
                                 defaultBaseURL: DefaultBaseURL)
    }
    
    init(accessKey: String, secretKey: String, redirectURI: String, accessScope: String, authorizeURLString: String, defaultBaseURL: String) {
        self.access_Key = accessKey
        self.secret_Key = secretKey
        self.redirect_URI = redirectURI
        self.access_Scope = accessScope
        self.default_Base_URL = defaultBaseURL
        self.authorize_URL_String = authorizeURLString
    }
}
