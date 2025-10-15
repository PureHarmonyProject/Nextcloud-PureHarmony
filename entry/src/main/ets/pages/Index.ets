import { LoginProcess, NCommon } from 'nextcloud';
import { webview } from '@kit.ArkWeb';
import { Logger } from '../utils/Logger';
import { App, promptAction } from '@kit.ArkUI';
import { Path } from '../utils/Path';
import { FolderPageBuilder } from './FolderPage';
import { UploadPage } from './UploadPage';

const TAG = "Page-Index";

const EXIT_TOAST_DURATION: number = 2000;

@Entry
@Component
struct Index {
    @State loginWebviewVisible: boolean = false;
    @State currentIndex: number = 0;
    @Provide('FolderList.Lanes') listLanes: number = 2;
    @Provide('FolderList.PathStack') pathStack: NavPathStack = new NavPathStack();
    private controller: webview.WebviewController = new webview.WebviewController();
    private loginProcess = new LoginProcess();
    private exitForSure: boolean = false;

    onBackPress(): boolean | void {
        Logger.Info(TAG, `onBackPressed`);
        if (this.pathStack.size() === 0) {
            if (this.exitForSure) {
                return false;
            }

            try {
                this.getUIContext().getPromptAction().showToast({
                    message: "Press again to exit",
                    duration: EXIT_TOAST_DURATION,
                });
            } catch (error) {
                Logger.Error(TAG, `Failed to show toast?`);
            }

            this.exitForSure = true;
            setTimeout(() => {
                this.exitForSure = false;
            }, EXIT_TOAST_DURATION);

            return true;
        }

        return true;
    }

    async doLogin() {
        if (!this.loginProcess.hasAppPassword()) {
            Logger.Debug(TAG, "No app password, start login process");
            try {
                await webview.WebCookieManager.clearAllCookies();
                let loginUrl = await this.loginProcess.initLogin();
                if (!loginUrl) {
                    Logger.Error(TAG, "Login failed");
                    return;
                }

                this.controller.loadUrl(loginUrl);
                Logger.Info(TAG, "Successfully opened login url");

                this.loginWebviewVisible = true;

                let result = await this.loginProcess.loginPollRepeatedly();
                Logger.Info(TAG, "Login result: " + JSON.stringify(result));
                this.loginWebviewVisible = false;

                AlertDialog.show({
                    title: "Login result",
                    message: "Welcome, " + result.loginName,
                });
            } catch (e) {
                AlertDialog.show({
                    title: "Login failed",
                    message: JSON.stringify(e),
                })
            }
            promptAction.showToast({
                message: "Goto back to tab 1!",
                duration: 5000,
            });

            this.pathStack.clear();
        } else {
            Logger.Info(TAG, "Already have app password, skip login process");
            AlertDialog.show({
                title: "Login result",
                message: "Welcome, " + NCommon.Preference.username,
            });
        }
    }

    aboutToAppear(): void {
        Logger.Info(TAG, `aboutToAppear`);
    }

    onPageShow() {
        App.setImageCacheCount(500);
        App.setImageRawDataCacheSize(1024 * 1024 * 100); // 100MB
        App.setImageFileCacheSize(1024 * 1024 * 500); // 100MB

        if (!this.loginProcess.hasAppPassword()) {
            promptAction.showToast({
                message: "Go to tab 2 to login",
                duration: 5000,
            });
        }
    }

    build() {
        Tabs({ barPosition: BarPosition.End }) {
            TabContent() {
                Flex({ direction: FlexDirection.Column }) {
                    Navigation(this.pathStack) {
                        FolderPageBuilder("", new Path())
                    }
                    .navBarWidth(0)
                    .mode(NavigationMode.Stack)

                    Row({ space: 10 }) {
                        Button("Lanes: " + this.listLanes)
                            .onClick(() => {
                                this.listLanes = (this.listLanes % 3) + 1;
                            })
                            .width(100)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                    .justifyContent(FlexAlign.Center)
                    .height(60)
                    .margin({ top: 10, bottom: 10 })

                }
            }
            .tabBar($r("app.string.tab_files"))
            .tabIndex(this.currentIndex)

            TabContent() {
                Flex({ direction: FlexDirection.Column }) {
                    Row() {
                        Button("Login")
                            .onClick(async () => {
                                await this.doLogin();
                            })

                        TextInput({ placeholder: 'WebRoot', text: NCommon.Preference.hostname })
                            .onChange((v) => {
                                NCommon.Preference.hostname = v;
                            })
                            .height(50)
                            .margin({ top: 10, bottom: 10 })
                    }
                    .width('100%')

                    Row() {
                        Text("Username: " + NCommon.Preference.username)
                            .height(50)
                            .margin({ top: 10, bottom: 10 })

                        Button("Logout")
                            .onClick(() => {
                                NCommon.Preference.password = "";
                                promptAction.showToast({
                                    message: "Logged out",
                                    duration: 2000,
                                });
                            })
                    }
                    .width('100%')

                    Web({ src: "about:blank", controller: this.controller })
                        .id("webview")
                        .width('100%')
                        .height('100%')
                        .flexGrow(1)
                        .border({ width: 1, color: Color.Red })
                }
            }
            .tabBar($r('app.string.tab_login'))

            TabContent() {
                UploadPage()
                    .width('100%')
                    .height('100%')
            }
            .tabBar($r('app.string.tab_upload'))
        }
        .width('100%')
        .height('100%')
        .scrollable(false)
    }
}
