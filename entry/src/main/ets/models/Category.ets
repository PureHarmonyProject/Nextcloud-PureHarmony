import { Logger, NCommon } from 'nextcloud';
import { ImageListDataSource } from './ImageListDataSource';
import { PhotoItem, UploadResult } from './PhotoItem';
import { promptAction } from '@kit.ArkUI';

const TAG = 'models/Category';

export enum AddAssetResult {
    Added,
    Unmatched,
    Throttled
}

const IMAGE_LIST_MAX_ITEMS = 100;

@Observed
export class Category implements NCommon.CategoryConfig {
    name: string;
    patterns: string[];
    location: string;
    /**
     * Items that are currently visible on the UI (not all assets are listed for performance reason)
     */
    visibleItems: ImageListDataSource = new ImageListDataSource();
    backedItems: PhotoItem[] = [];

    constructor(other: NCommon.CategoryConfig) {
        this.name = other.name;
        this.patterns = other.patterns;
        this.location = other.location;
    }

    tryAddAsset(asset: PhotoItem): AddAssetResult {
        for (let p of this.patterns) {
            if (RegExp(p).test(asset.displayName)) {
                if (this.visibleItems.totalCount() > IMAGE_LIST_MAX_ITEMS) {
                    this.backedItems.push(asset);
                    return AddAssetResult.Throttled;
                } else {
                    this.visibleItems.addAsset(asset)
                    return AddAssetResult.Added;
                }
            }
        }
        return AddAssetResult.Unmatched;
    }

    showNext50(): void {
        Logger.Info(TAG, `loadNext50 enter`);
        let count = 0;
        while (this.backedItems.length > 0 && count < 50) {
            let asset = this.backedItems.shift()!;
            this.visibleItems.addAsset(asset);
            count++;
        }
    }

    getAssets(start: number, length: number): PhotoItem[] {
        let result: PhotoItem[] = [];
        // Get from items if it's completely within range
        if (start + length <= this.visibleItems.totalCount()) {
            result = this.visibleItems.getDataRange(start, length);
        } else if (start >= this.visibleItems.totalCount()) {
            // Get from backedItems if it's completely within backedItems
            let backedStart = start - this.visibleItems.totalCount();
            for (let i = backedStart; i < Math.min(backedStart + length, this.backedItems.length); i++) {
                result.push(this.backedItems[i]);
            }
        } else {
            // Get from both items and backedItems
            let itemsPartLength = this.visibleItems.totalCount() - start;
            result = this.visibleItems.getDataRange(start, itemsPartLength);
            let backedPartLength = length - itemsPartLength;
            for (let i = 0; i < Math.min(backedPartLength, this.backedItems.length); i++) {
                result.push(this.backedItems[i]);
            }
        }
        return result;
    }

    getTotalAvailableCount(): number {
        return this.visibleItems.totalCount() + this.backedItems.length;
    }

    async uploadAllAssets() {
        const BATCH_SIZE = 8;
        let total = Math.ceil(this.getTotalAvailableCount() / BATCH_SIZE) * BATCH_SIZE;
        for (let i = 0; i < total; i += BATCH_SIZE) {
            let batch = this.getAssets(i, BATCH_SIZE);

            let canStop = true;

            let futures = batch.map(asset => {
                return asset.upload(NCommon.Preference.baseUploadDirectory + this.location).then((result) => {
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
}
