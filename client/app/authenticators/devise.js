import DeviseAuthenticator from 'ember-simple-auth/authenticators/devise';

export default class Authenticator extends DeviseAuthenticator {
  serverTokenEndpoint = '/api/users/sign_in'
  resourceName = 'user'
}