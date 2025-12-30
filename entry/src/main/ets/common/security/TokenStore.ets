import preferences from '@ohos.data.preferences';
import ability from '@ohos.app.ability.common';

type AbilityContext = ability.Context;

const PREF_FILE = 'repoflow_auth';
const KEY_ACCESS_TOKEN = 'access_token';
const KEY_STATE = 'oauth_state';

export class TokenStore {
  private accessToken: string = '';
  private state: string = '';
  private pref?: preferences.Preferences;

  async init(context: AbilityContext): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_FILE);
      // Always reload from storage to get latest values
      this.accessToken = await this.pref.get(KEY_ACCESS_TOKEN, '') as string;
      this.state = await this.pref.get(KEY_STATE, '') as string;
    } catch (err) {
      console.error('TokenStore init failed', JSON.stringify(err));
    }
  }

  getAccessToken(): string {
    return this.accessToken;
  }

  async setAccessToken(token: string): Promise<void> {
    this.accessToken = token;
    if (this.pref) {
      try {
        await this.pref.put(KEY_ACCESS_TOKEN, token);
        await this.pref.flush();
      } catch (err) {
        console.error('TokenStore setAccessToken failed', JSON.stringify(err));
      }
    }
  }

  async clearAccessToken(): Promise<void> {
    this.accessToken = '';
    if (this.pref) {
      try {
        await this.pref.put(KEY_ACCESS_TOKEN, '');
        await this.pref.flush();
      } catch (err) {
        console.error('TokenStore clearAccessToken failed', JSON.stringify(err));
      }
    }
  }

  getState(): string {
    return this.state;
  }

  async setState(state: string): Promise<void> {
    this.state = state;
    if (this.pref) {
      try {
        await this.pref.put(KEY_STATE, state);
        await this.pref.flush();
      } catch (err) {
        console.error('TokenStore setState failed', JSON.stringify(err));
      }
    }
  }
}
