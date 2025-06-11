# Names

### Configuration

Each resource that can be created by the Common library supports the following fields to control the generated resource name, along with the resource identifier.

All of these fields support the use of Helm templates for advanced naming requirements.

#### forceRename

Override the default resource name entirely.

!!! info
    The `forceRename` field is mutually exclusive with the `prefix` and `suffix` fields.

#### prefix

Prefix to prepend to the resource name. Will not be added if the resource name already starts with the prefix.

#### suffix

Suffix to append to the resource name. Will not be added if the resource name already ends with the suffix. Defaults to the resource identifier if there are multiple enabled items, otherwise it defaults to an empty value.

### Behavior

By default, all resource names are based on the `bjw-s.common.lib.chart.names.fullname` template which defaults to the Helm Release name. This template can be further controlled by the `global.nameOverride` and `global.fullnameOverride` values.

The resource identifier (key) is only appended when there are multiple resources of the same kind or if the value `global.alwaysAppendIdentifierToResourceName` is set to `true`.

!!! info
    When the resource name already equals the identifier or if the identifier suffix is already present, it will not be added a second time. This is to prevent names like `vaultwarden-vaultwarden`

Assuming a Helm Release with the name `base_name`, the following table gives an overview of how the resource name is generated:

| `forceRename`                | Enabled items | Always append identifier | `identifier`  | `prefix`      | `suffix`    | Expected name                 | Notes |
|------------------------------|---------------|--------------------------|---------------|---------------|-------------|-------------------------------|--------------------------------------------------|
| `custom-name`                |               |                          |               |               |             | `custom-name`                 | Force rename overrides all logic                 |
| `"{{ .Release.Namespace }}"` |               |                          |               |               |             | `default`                     | Force rename with a template overrides all logic |
|                              | 1             |                          | `abc`         |               |             | `base_name`                   | Base case, no additional configuration           |
|                              | 1             |                          | `abc`         | `team`        |             | `team-base_name`              | Prefix added                                     |
|                              | 1             |                          | `abc`         | `base_name`   |             | `base_name`                   | Prefix equal to fullname – skipped               |
|                              | 1             |                          | `abc`         |               | `svc`       | `base_name-svc`               | Suffix added                                     |
|                              | 1             |                          | `abc`         |               | `base_name` | `base_name`                   | Suffix equal to fullname - skipped               |
|                              | 1             |                          | `abc`         | `team`        | `svc`       | `team-base_name-svc`          | Prefix + suffix, no identifier                   |
|                              | 1             | `true`                   | `abc`         |               |             | `base_name-abc`               | identifier suffix via global flag                |
|                              | 1             | `true`                   | `abc`         | `team`        | `svc`       | `team-base_name-abc-svc`      | Prefix + identifier + suffix via global flag     |
|                              | 2             |                          | `abc`         |               |             | `base_name-abc`               | Identifier due to itemCount > 1                  |
|                              | 2             |                          | `abc`         | `team`        | `svc`       | `team-base_name-abc-svc`      | Prefix + Identifier + Suffix                     |
|                              | 2             |                          | `base_name`   |               |             | `base_name`                   | Identifier equal to fullname – skipped           |
|                              | 2             |                          | `abc`         |               | `abc`       | `base_name-abc`               | Suffix skipped – already included by identifer   |
