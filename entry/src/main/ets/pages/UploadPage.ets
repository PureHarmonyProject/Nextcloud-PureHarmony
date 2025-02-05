import { Logger } from '../utils/Logger';
import { PermissionManager } from '../utils/PermissionManager';
import { ImageListDataSource, PhotoItem, UploadStatus } from '../models/MediaListDataSource';
import { CategoriesListDataSource, Category, UploadLocation } from '../models/CategoryListDataSource';
import { UploadFile } from 'nextcloud';
import { LengthMetrics, promptAction } from '@kit.ArkUI';
import { TimeToPath } from '../utils/Utils';
import { image } from '@kit.ImageKit';

const TAG = "Page-UploadPage"

const LOCATION_CAMERA = new UploadLocation('Camera/');
const LOCATION_SCREENSHOTS = new UploadLocation('Screenshots/');
const LOCATION_OTHERS = new UploadLocation('Others/');

const DEFAULT_CATEGORIES: Category[] = [
    new Category('Camera', [
        String.raw`^(IMG)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})(_\d{3})?(_\d+)?.(\w+)$`,
        String.raw`^(S?VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2}).(\w+)$`,
    ], LOCATION_CAMERA),
    new Category('Screenshot', [
        String.raw`^(screenshot)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2}).(\w+)$`,
        String.raw`^(S?VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})_\d+.(\w+)$`
    ], LOCATION_SCREENSHOTS),
    new Category('Misc', [
        String.raw`^(IMG)_(\d+).(\w+)$`,
        String.raw`^(image)_(\d+).(\w+)$`,
        String.raw`^(S?VID)_(\d+).(\w+)$`,
        String.raw`^(alipay)_(\d+).(\w+)$`,
    ], LOCATION_OTHERS),
];

@Component
struct PhotoView {
    @ObjectLink asset: PhotoItem;
    @Prop category: Category;
    @State private thumbnail: PixelMap | null = null;

    build() {
        Stack() {
            Image(this.thumbnail)
                .height(100)
                .width(100)
                .objectFit(ImageFit.Cover)

            Text(this.asset.isVideo ? '▶' : '')
                .fontSize(48)
                .fontFamily('monospace')
                .fontColor(Color.Red)
        }
        .draggable(false)
        .height(100)
        .width(100)
        .borderWidth(3)
        .borderColor(
            (this.asset.uploadStatus == UploadStatus.Uploaded) ? Color.Green :
                (this.asset.uploadStatus == UploadStatus.Uploading) ? Color.Yellow :
                    (this.asset.uploadStatus == UploadStatus.Failed) ? Color.Red :
                        (this.asset.uploadStatus == UploadStatus.None) ? Color.Gray :
                            (this.asset.uploadStatus == UploadStatus.Existed) ? Color.Blue : Color.Gray)
        .onAppear(async () => {
            this.thumbnail = await this.asset.asset.getThumbnail({ height: 200, width: 200 });
        })
        .onClick(async () => {
            await this.doUpload();
        })
    }

    private async doUpload() {
        this.asset.uploadStatus = UploadStatus.Uploading;
        let fd = await this.asset.getReadOnlyFd();
        let path = this.category.location.toString() + TimeToPath(this.asset.dateTaken);
        // let mkdirResult = await CreatePath(path);
        // if (mkdirResult !== 201 && mkdirResult !== 409 && mkdirResult !== 405) {
        //     // 405 is the status code for "already exists"
        //     Logger.Error(TAG, `Failed to create path: ${path}`);
        //     promptAction.showToast({
        //         message: `Failed to create path: ${path}: ${mkdirResult}`,
        //         duration: 2000,
        //     });
        //     await asset.close(fd);
        //     return;
        // }

        let message = "";
        let uploadResult = await UploadFile(this.asset.displayName, path, fd);
        if (uploadResult !== 201 && uploadResult !== 204) {
            message = `Failed: ${this.asset.displayName}: ${uploadResult}`;
            this.asset.uploadStatus = UploadStatus.Failed;
        } else if (uploadResult === 204) {
            message = `File Existed: ${this.asset.displayName}`;
            this.asset.uploadStatus = UploadStatus.Existed;
        } else {
            message = `Uploaded: ${this.asset.displayName}`;
            this.asset.uploadStatus = UploadStatus.Uploaded;
        }

        promptAction.showToast({ message, duration: 2000 });
        await this.asset.close(fd);
    }
}

@Component
struct PhotosGridView {
    @ObjectLink category: Category;
    private scroller: Scroller = new Scroller();

    build() {
        Grid(this.scroller) {
            LazyForEach(new ImageListDataSource(this.category.patterns), (asset: PhotoItem) => {
                GridItem() {
                    PhotoView({ asset: asset, category: this.category })
                }
                .width('100%')
            })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .scrollBar(BarState.On)
        .edgeEffect(EdgeEffect.Spring)
        .columnsGap(8)
        .rowsGap(8)
        .cachedCount(2)
        .width('100%')
        .height('auto')
    }
}


@Preview
@Component
export struct UploadPage {
    @State private categories: CategoriesListDataSource = new CategoriesListDataSource();

    async aboutToAppear() {
        let result = await PermissionManager.RequestPermission(getContext(this), 'ohos.permission.READ_IMAGEVIDEO')
        Logger.Info(TAG, `Request permission result: ${result}`);
        this.categories.loadCategories(DEFAULT_CATEGORIES);
    }

    build() {
        Tabs() {
            ForEach(this.categories.getAllCategories(), (category: Category) => {
                TabContent() {
                    Flex({ direction: FlexDirection.Column, space: { main: LengthMetrics.px(20) } }) {
                        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Baseline }) {
                            Text(category.name)
                                .fontWeight(FontWeight.Bold)
                                .fontSize(24)

                            Text(category.location.toString())
                        }
                        .height('32')

                        ForEach(category.patterns, (pattern: string) => {
                            Text(pattern)
                                .fontSize(12)
                                .fontColor(Color.Green)
                                .fontFamily('serif')
                        })

                        PhotosGridView({ category: category })
                    }
                    .width('100%')
                    .height('100%')
                }
                .margin(10)
                .tabBar(category.name)
            })
        }
    }
}
