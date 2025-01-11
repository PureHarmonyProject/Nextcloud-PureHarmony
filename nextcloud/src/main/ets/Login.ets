import { Logger } from './Logger';
import { CoreClientFlowLoginV2Api, CoreLoginFlowV2Credentials, Configuration } from './nextcloud-api-sdk';
import { NCommon } from './Common';

const TAG = "Nextcloud-Login";

class LoginProcess {
    private loginApi: CoreClientFlowLoginV2Api | null = null;
    private token: string = "";

    hasAppPassword(): boolean {
        return NCommon.Preference.password !== "";
    }

    async initLogin(): Promise<string | null> {
        let apiConfig = new Configuration({
            basePath: "https://" + NCommon.Preference.hostname,
            baseOptions: {
                headers: { "User-Agent": NCommon.USER_AGENT() },
            }
        });

        this.loginApi = new CoreClientFlowLoginV2Api(apiConfig);
        try {
            let flow = (await this.loginApi.coreClientFlowLoginV2Init()).data;
            this.token = flow.poll.token;
            return flow.login;
        } catch (e) {
            Logger.Error(TAG, "ERROR " + e);
            return null;
        }
    }

    async loginPollRepeatedly(): Promise<CoreLoginFlowV2Credentials> {
        Logger.Info(TAG, "Polling for login result...");
        let result = await this.loginPoll();
        while (!result) {
            await new Promise<never>(resolve => setTimeout(resolve, 2500));
            result = await this.loginPoll();
        }

        NCommon.Preference.password = result.appPassword;
        NCommon.Preference.username = result.loginName;
        return result;
    }

    private async loginPoll(): Promise<CoreLoginFlowV2Credentials | null> {
        if (this.loginApi == null) {
            Logger.Error(TAG, "unreachable");
            return null;
        }

        try {
            Logger.Debug(TAG, "  -> Polling...");
            return (await this.loginApi.coreClientFlowLoginV2Poll(this.token)).data;
        } catch (e) {
            return null;
        }
    }
}

export { LoginProcess };
