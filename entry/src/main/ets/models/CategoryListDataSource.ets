import { BasicDataSource } from "nextcloud";
import { INSTANT_UPLOAD_PATH } from "../utils/GlobalStorage";

@Observed
export class UploadLocation {
    path: string;

    constructor(path: string) {
        this.path = path;
    }

    toString(): string {
        return INSTANT_UPLOAD_PATH + this.path;
    }
}

@Observed
export class Category {
    name: string;
    patterns: string[];
    location: UploadLocation;

    constructor(name: string, patterns: string[], location: UploadLocation) {
        this.name = name;
        this.patterns = patterns;
        this.location = location;
    }

    matches(name: string): boolean {
        for (let p of this.patterns) {
            if (RegExp(p).test(name)) {
                return true;
            }
        }

        return false;
    }

    apply(name: string): string {
        for (let p of this.patterns) {
            if (RegExp(p).test(name)) {
                return name.replace(RegExp(p), this.name);
            }
        }

        return name;
    }
}

@Observed
export class CategoriesListDataSource extends BasicDataSource<Category> {
    private static OtherCategory = new Category("Unmatched", [".*"], new UploadLocation("Others/"));

    addCategory(name: string, patterns: string[], location: UploadLocation) {
        this.entries.push(new Category(name, patterns, location));
        this.notifyDataAdd(this.entries.length - 1);
    }

    loadCategories(items: Category[]) {
        this.entries = items;
        for (let i = 0; i < items.length; i++) {
            this.notifyDataAdd(i);
        }
    }

    removeCategory(index: number) {
        this.entries.splice(index, 1);
        this.notifyDataDelete(index);
    }

    getAllCategories(): Category[] {
        return this.entries;
    }

    indexOf(item: Category): number {
        return this.entries.indexOf(item);
    }

    getCategoryForName(name: string): Category {
        for (let item of this.entries) {
            if (item.matches(name)) {
                return item;
            }
        }
        return CategoriesListDataSource.OtherCategory;
    }

    hasCategoryForName(name: string): boolean {
        for (let item of this.entries) {
            if (item.matches(name)) {
                return true;
            }
        }
        return false;
    }
}
