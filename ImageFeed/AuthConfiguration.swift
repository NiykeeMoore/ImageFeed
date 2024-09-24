import Foundation
/*
 Если апишка превышена, подставить другие данные чтоб не ждать кулдауна
 static let accessKey = "YY_3VaSwj3Nc40rzgGRkT6lskWXQwf41jWouLeOq1mc" // первый акк
 static let secretKey = "onZ7lEXc1mrwN2yZ6vTWXO2r1SMBrt3L2pGdP_uCzek" // первый акк
 
 static let accessKey = "45l6mwJ-T8m-CKm-oXNOnC9qiwZ4n_yt1YPr58Fh4H8" // второй акк
 static let secretKey = "mRO43z5gFTB5c8mUa10maCYC07vmQjljEIpS0qbuVl0" // второй акк
 */

enum Constants {
    static let defaultBaseURL = "https://api.unsplash.com"
    static let authorizeURLString = "https://unsplash.com/oauth/authorize"
    static let accessKey = "YY_3VaSwj3Nc40rzgGRkT6lskWXQwf41jWouLeOq1mc" // первый акк
    static let secretKey = "onZ7lEXc1mrwN2yZ6vTWXO2r1SMBrt3L2pGdP_uCzek" // первый акк
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    
}
