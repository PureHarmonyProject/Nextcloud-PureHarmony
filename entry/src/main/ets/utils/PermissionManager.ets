import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from 'nextcloud';

const TAG = 'utils/PermissionManager';

export class PermissionManager {
    static async RequestPermission(context: Context, permission: Permissions): Promise<boolean> {
        let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

        if (await PermissionManager.verifyPermission(permission)) {
            Logger.Info(TAG, `requestPermission success, permissionName->${permission}`);
            return true;
        }

        let result = await atManager.requestPermissionsFromUser(context, [permission]);

        for (let i = 0; i < result.permissions.length; i++) {
            let rPerm = result.permissions[i];
            let rResult = result.authResults[i];

            if (rPerm == permission && rResult == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
                Logger.Info(TAG, `requestPermission success, permissionName->${permission}`);
                return true;
            }
        }

        Logger.Warn(TAG, `requestPermission fail, ${permission}, requesting to open settings`);
        await AlertDialog.show({ message: '请开启权限' });
        await atManager.requestPermissionOnSetting(context, [permission]);
        return false;
    }

    private static async verifyPermission(permission: Permissions): Promise<boolean> {
        let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
        let tokenID: number = (await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION))
            .appInfo
            .accessTokenId;
        let result: boolean = false;
        await atManager.verifyAccessToken(tokenID, permission).then((data: abilityAccessCtrl.GrantStatus) => {
            result = data == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        }).catch((err: BusinessError) => {
            Logger.Error(TAG, `verifyPermission fail, err->${JSON.stringify(err)}`);
        });
        return result;
    }
}
