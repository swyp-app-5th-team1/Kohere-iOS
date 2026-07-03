//
//  AuthInterface.swift
//  Kohere
//
//  Created by mandoo on 6/30/26.
//

protocol AuthInterface {
    func socialLogin(credential: SocialLoginCredential) async throws -> Auth
    func reissue(refreshToken: String) async throws -> AuthToken
    func logout(accessToken: String, refreshToken: String) async throws
}
