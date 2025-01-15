import { DirectoryEntry } from './webdav/DirEntryParserStateMachine';
import { ListFiles } from './webdav/Files';

class BasicDataSource<T> implements IDataSource {
    protected entries: T[] = [];
    private listeners: DataChangeListener[] = [];

    public totalCount(): number {
        return this.entries.length;
    }

    public getData(index: number): T {
        return this.entries[index];
    }

    registerDataChangeListener(listener: DataChangeListener): void {
        if (this.listeners.indexOf(listener) < 0) {
            this.listeners.push(listener);
        }
    }

    unregisterDataChangeListener(listener: DataChangeListener): void {
        const pos = this.listeners.indexOf(listener);
        if (pos >= 0) {
            this.listeners.splice(pos, 1);
        }
    }

    notifyDataReload(): void {
        this.listeners.forEach(listener => {
            listener.onDataReloaded();
        })
    }

    notifyDataAdd(index: number): void {
        this.listeners.forEach(listener => {
            listener.onDataAdd(index);
        })
    }

    notifyDataChange(index: number): void {
        this.listeners.forEach(listener => {
            listener.onDataChange(index);
        })
    }

    notifyDataDelete(index: number): void {
        this.listeners.forEach(listener => {
            listener.onDataDelete(index);
        })
    }

    notifyDataMove(from: number, to: number): void {
        this.listeners.forEach(listener => {
            listener.onDataMove(from, to);
        })
    }

    notifyDatasetChange(operations: DataOperation[]): void {
        this.listeners.forEach(listener => {
            listener.onDatasetChange(operations);
        })
    }
}

export class FilesDataSource extends BasicDataSource<DirectoryEntry> {
    constructor(path: string) {
        ListFiles(path).then(entries => {
            entries = entries.sort((a: DirectoryEntry, b: DirectoryEntry) => {
                // Directories first, then sort by name
                if (a.isDirectory && !b.isDirectory) {
                    return -1;
                } else if (!a.isDirectory && b.isDirectory) {
                    return 1;
                } else {
                    return a.name.localeCompare(b.name);
                }
            })

            this.entries = entries;
            this.notifyDataReload();
        });
        super();
    }
}
