import { CreatePath, Logger, UploadFile } from 'nextcloud';
import { PermissionManager } from '../utils/PermissionManager';
import { ImageListDataSource, PhotoItem, UploadStatus } from '../models/MediaListDataSource';
import { CategoriesListDataSource, Category, UploadLocation } from '../models/CategoryListDataSource';
import { LengthMetrics, promptAction } from '@kit.ArkUI';
import { TimeToPath } from '../utils/Utils';

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

enum UploadResult {
    FAILED,
    EXISTED,
    SUCCEEDED,
};

async function doUploadAsset(asset: PhotoItem, category: Category): Promise<UploadResult> {
    asset.uploadStatus = UploadStatus.Uploading;
    let path = category.location.toString() + TimeToPath(asset.dateTaken);
    let mkdirResult = await CreatePath(path);
    if (mkdirResult !== 201 && mkdirResult !== 409 && mkdirResult !== 405) {
        // 405 is the status code for "already exists"
        Logger.Error(TAG, `Failed to create path: ${path}`);
        promptAction.showToast({
            message: `Failed to create path: ${path}: ${mkdirResult}`,
            duration: 2000,
        });
        return UploadResult.FAILED;
    }

    let ret: UploadResult = UploadResult.FAILED;

    let message = "";
    let fd = await asset.getReadOnlyFd();
    let uploadResult = await UploadFile(asset.displayName, asset.dateTakenMs, path, fd);
    asset.close(fd);
    if (uploadResult !== 201 && uploadResult !== 204) {
        message = `Failed: ${asset.displayName}: ${uploadResult}`;
        asset.uploadStatus = UploadStatus.Failed;
        ret = UploadResult.FAILED;
    } else if (uploadResult === 204) {
        message = `File Existed: ${asset.displayName}`;
        asset.uploadStatus = UploadStatus.Existed;
        ret = UploadResult.EXISTED;
    } else {
        message = `Uploaded: ${asset.displayName}`;
        asset.uploadStatus = UploadStatus.Uploaded;
        ret = UploadResult.SUCCEEDED;
    }

    if (ret !== UploadResult.EXISTED) {
        promptAction.showToast({ message, duration: 2000 });
    }
    return ret;
}

async function doUploadAllAssets(dataSource: ImageListDataSource, category: Category) {
    const BATCH_SIZE = 8;
    let total = Math.ceil(dataSource.totalCount() / BATCH_SIZE) * BATCH_SIZE;
    for (let i = 0; i < total; i += BATCH_SIZE) {
        let batch = dataSource.getDataRange(i, BATCH_SIZE);

        let canStop = true;

        let futures = batch.map(asset => {
            return doUploadAsset(asset, category).then((result) => {
                canStop = canStop && result === UploadResult.EXISTED;
            });
        });

        await Promise.all(futures);
        if (canStop) {
            promptAction.showToast({
                message: `Upload is probably completed`,
                duration: 2000,
            });
            break;
        }
    }
}

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
            await doUploadAsset(this.asset, this.category);
        })
    }
}

@Component
struct PhotosGridView {
    @ObjectLink category: Category;
    private scroller: Scroller = new Scroller();
    private dataSource: ImageListDataSource = new ImageListDataSource(this.category.patterns);

    build() {
        Stack() {
            Grid(this.scroller) {
                LazyForEach(this.dataSource, (asset: PhotoItem) => {
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

            Column() {
                Button(`Upload All`)
                    .onClick(() => {
                        Logger.Info(TAG, `Upload all in '${this.category.name}'`);
                        doUploadAllAssets(this.dataSource, this.category);
                    })
                    .width('30%')
            }
            .width('100%')
            .position({ bottom: 5 })
        }
    }
}


@Preview
@Component
export struct UploadPage {
    @State private categories: CategoriesListDataSource = new CategoriesListDataSource();

    async aboutToAppear() {
        let result1 = await PermissionManager.RequestPermission(getContext(this), 'ohos.permission.READ_IMAGEVIDEO');
        Logger.Info(TAG, `Request permission result: ${result1}`);
        let result2 = await PermissionManager.RequestPermission(getContext(this), 'ohos.permission.MEDIA_LOCATION');
        Logger.Info(TAG, `Request permission result: ${result2}`);
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
