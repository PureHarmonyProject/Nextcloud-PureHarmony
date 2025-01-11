const DAV_PROPERTY_TYPES = [
  'd:creationdate',
  'd:displayname',
  'd:getcontentlanguage',
  'd:getcontentlength',
  'd:getcontenttype',
  'd:getetag',
  'd:getlastmodified',
  'd:lockdiscovery',
  'd:quota-available-bytes',
  'd:quota-used-bytes',
  'd:supportedlock',
  'nc:acl-can-manage',
  'nc:acl-enabled',
  'nc:acl-list',
  'nc:contained-file-count',
  'nc:contained-folder-count',
  'nc:creation_time',
  'nc:data-fingerprint',
  'nc:group-folder-id',
  'nc:has-preview',
  'nc:hidden',
  'nc:inherited-acl-list',
  'nc:is-encrypted',
  'nc:is-mount-root',
  'nc:lock',
  'nc:lock-owner',
  'nc:lock-owner-displayname',
  'nc:lock-owner-editor',
  'nc:lock-owner-type',
  'nc:lock-time',
  'nc:lock-timeout',
  'nc:lock-token',
  'nc:mount-type',
  'nc:note',
  'nc:reminder-due-date',
  'nc:rich-workspace',
  'nc:rich-workspace-file',
  'nc:share-attributes',
  'nc:sharees',
  'nc:upload_time',
  'nc:version-author',
  'nc:version-label',
  'oc:checksums',
  'oc:comments-count',
  'oc:comments-href',
  'oc:comments-unread',
  'oc:downloadURL',
  'oc:favorite',
  'oc:fileid',
  'oc:id',
  'oc:owner-display-name',
  'oc:owner-id',
  'oc:permissions',
  'oc:share-types',
  'oc:size',
  'oc:tags',
  'ocm:share-permissions',
  'ocs:share-permissions'
];

type DavPropsType = typeof DAV_PROPERTY_TYPES[number];


interface DavProps {
  [key: DavPropsType]: string;

  'd:resourcetype'?: 'd:collection',
}

interface DavPropstat {
  'd:prop': DavProps;
  'd:status': string;
}

interface DavResponse {
  'd:href': string;
  'd:propstat': DavPropstat;
}

interface DavMultiStatus {
  'd:response': DavResponse[];
}

interface DavResponseRoot {
  'd:multistatus': DavMultiStatus;
}

export { DAV_PROPERTY_TYPES, DavPropsType, DavProps, DavPropstat, DavResponse, DavMultiStatus, DavResponseRoot, };
