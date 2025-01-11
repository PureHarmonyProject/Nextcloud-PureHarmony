import { FilesDataSource, DirectoryEntry, LoginProcess, NCommon, ListFiles } from 'nextcloud';
import { webview } from '@kit.ArkWeb';
import { Logger } from '../common/Logger';
import { App, promptAction } from '@kit.ArkUI';

// const PERMISSION_IMAGE_VIDEO: Permissions = 'ohos.permission.READ_IMAGEVIDEO';

const TAG = "Page-Index";

const EXIT_TOAST_DURATION: number = 2000;

function formatBytes(bytes: string) {
    let bytesNum = parseInt(bytes);
    let units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let i = 0;
    while (bytesNum >= 1024) {
        bytesNum /= 1024;
        i++;
    }

    return bytesNum.toFixed(2) + ' ' + units[i];
}

function constructPreviewUrl(fileId: string): string {
    return "https://" + NCommon.Preference.username + ":" + NCommon.Preference.password + "@" +
    NCommon.Preference.hostname + "/" + "/core/preview?fileId=" + fileId + "&x=64&y=64&mimeFallback=true"
}

@Entry
@Component
struct Index {
    @State loginWebviewVisible: boolean = false;
    @State currentIndex: number = 0;
    @State nLanes: number = 1;
    private CurrentPath: string = "/";
    private controller: webview.WebviewController = new webview.WebviewController();
    private dataSource = new FilesDataSource();
    private loginProcess = new LoginProcess();
    private exitForSure: boolean = false;

    onBackPress(): boolean | void {
        if (this.CurrentPath === "/") {
            if (this.exitForSure) {
                return false;
            }

            promptAction.showToast({
                message: "Press again to exit",
                duration: EXIT_TOAST_DURATION,
            });

            this.exitForSure = true;
            setTimeout(() => {
                this.exitForSure = false;
            }, EXIT_TOAST_DURATION);

            return true;
        }

        this.goUp();
        return true;
    }

    async doLogin() {
        if (!this.loginProcess.hasAppPassword()) {
            Logger.Debug(TAG, "No app password, start login process");
            try {
                let loginUrl = await this.loginProcess.initLogin();
                if (!loginUrl) {
                    Logger.Error(TAG, "Login failed");
                    return;
                }

                this.controller.loadUrl(loginUrl);
                Logger.Info(TAG, "Successfully opened login url");

                this.loginWebviewVisible = true;
                this.currentIndex = 1;

                let result = await this.loginProcess.loginPollRepeatedly();
                Logger.Info(TAG, "Login result: " + JSON.stringify(result));
                this.loginWebviewVisible = false;
                this.currentIndex = 0;

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

            this.changeDirectory("/");
        } else {
            Logger.Info(TAG, "Already have app password, skip login process");
            AlertDialog.show({
                title: "Login result",
                message: "Welcome, " + NCommon.Preference.username,
            });
        }
    }

    async changeDirectory(absDir: string) {
        if (!this.loginProcess.hasAppPassword()) {
            promptAction.showToast({
                message: "Please login first",
                duration: 5000,
            });
            return;
        }
        try {
            let result = await ListFiles(absDir);
            Logger.Info(TAG, "List files result: " + JSON.stringify(result));

            this.dataSource.eraseData();
            for (let d of result) {
                this.dataSource.pushData(d);
            }
            this.dataSource.notifyDataReload();

            this.CurrentPath = absDir;
        } catch (e) {
            Logger.Error(TAG, "Failed to list files: " + JSON.stringify(e));
        }
    }

    async goUp() {
        let parts = this.CurrentPath.split("/").filter(p => p !== "");
        parts.pop();
        if (parts.length === 0) {
            await this.changeDirectory("/");
            return;
        }

        await this.changeDirectory("/" + parts.join("/") + "/");
    }

    async aboutToAppear(): Promise<void> {
        if (this.loginProcess.hasAppPassword()) {
            await this.changeDirectory("/");
        }
    }

    onPageShow() {
        App.setImageCacheCount(500);
        App.setImageRawDataCacheSize(1024 * 1024 * 100); // 100MB
        App.setImageFileCacheSize(1024 * 1024 * 500); // 100MB

        if (this.loginProcess.hasAppPassword()) {
            this.changeDirectory("/");
        } else {
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
                    List({ space: 5 }) {
                        LazyForEach(this.dataSource, (d: DirectoryEntry) => {
                            ListItem() {
                                Button({ type: ButtonType.Normal }) {
                                    Row() {
                                        if (d.has_preview) {
                                            Image(constructPreviewUrl(d.fileId))
                                                .width(32)
                                                .height(32)
                                                .margin({ right: 10 })
                                        } else {
                                            Text(d.isDirectory ? '📁' :
                                                (d.mime.startsWith("image") ? "🖼️" :
                                                    (d.mime.startsWith("video") ? '🎥' : '📄')))
                                                .fontSize(32)
                                                .margin({ right: 10 })
                                        }

                                        Column() {
                                            Text(d.name.replace(/\/$/, ''))
                                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                                .maxLines(1)
                                                .margin({ bottom: 2 })

                                            Text(d.isDirectory ? 'directory' :
                                                (d.mime + ' (' + formatBytes(d.size) + ')'))
                                                .fontSize(10)
                                                .maxLines(1)
                                                .fontStyle(FontStyle.Italic)
                                        }
                                        .alignItems(HorizontalAlign.Start)
                                        .width(this.nLanes == 1 ? '75%' : '70%')
                                    }
                                }
                                .backgroundColor('#00000000')
                                .borderRadius(0)
                                .onClick(async () => {
                                    if (d.isDirectory) {
                                        await this.changeDirectory(this.CurrentPath + d.name);
                                    }
                                })
                                .width('100%')
                                .height(64)
                                .padding({ left: 10, right: 10 })
                            }
                        })
                    }
                    .lanes(this.nLanes)
                    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
                    .width('auto')
                    .height('auto')
                    .flexGrow(1)
                    .cachedCount(5)

                    Row({ space: 10 }) {
                        Button("Load Root")
                            .onClick(async () => {
                                await this.changeDirectory("/");
                            })
                            .width(100)

                        Button("Go Up")
                            .onClick(async () => {
                                await this.goUp();
                            })
                            .width(100)

                        Button("Lanes: " + this.nLanes)
                            .onClick(() => {
                                this.nLanes = this.nLanes === 1 ? 2 : 1;
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
            .tabBar("Login Page")
        }
        .width('100%')
        .height('100%')
    }
}
