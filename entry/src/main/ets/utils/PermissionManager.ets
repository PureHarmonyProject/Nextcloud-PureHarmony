import hilog from '@ohos.hilog';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class PermissionManager {
    async verifyPermission(permission: Permissions): Promise<boolean> {
        let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
        let tokenID: number = (await
        bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION))
            .appInfo
            .accessTokenId;
        let result: boolean = false;
        await atManager.verifyAccessToken(tokenID, permission).then((data: abilityAccessCtrl.GrantStatus) => {
            result = data == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        }).catch((err: BusinessError) => {
            hilog.error(0x0000, 'testTag', `verifyPermission fail, err->${JSON.stringify(err)}`);
        });
        return result;
    }

    async tryRequestPermission(context: common.UIAbilityContext, permission: Permissions): Promise<boolean> {
        let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

        if (await this.verifyPermission(permission)) {
            hilog.info(0x0000, 'testTag', `requestPermission success, permissionName->${permission}`);
            return true;
        }

        let result = await atManager.requestPermissionsFromUser(context, [permission]);
        if (result.permissions[0] == permission &&
            result.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            hilog.info(0x0000, 'testTag', `requestPermission success, permissionName->${permission}`);
            return true;
        } else {
            hilog.warn(0x0000, 'testTag',
                `requestPermission fail, permissionName->${permission}, requesting to open settings`);
            await AlertDialog.show({ message: '请开启权限' });
            await atManager.requestPermissionOnSetting(context, [permission]);
            return false;
        }
    }
}

export default PermissionManager;

//
// let hasPermission = this.verifyPermission(permissionName);
// while (!hasPermission) {
//     this.tryRequestPermission(getContext(this) as common.UIAbilityContext, permissionName);
//     hasPermission = this.verifyPermission(permissionName);
// }