import Controller from '@ember/controller';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class SessionsController extends Controller {
  @service session;
  @tracked email = '';
  @tracked password = '';

  @action login() {
    console.log('firing');
    this.session.authenticate('authenticator:devise', email, password);
  }
}
