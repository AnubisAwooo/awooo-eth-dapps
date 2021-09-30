// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * 访问控制外部接口方法 支持 ERC165 测试
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * 某角色被设置成 Admin 替换之前的 Admin 角色 会触发 RoleAdminChanged 事件
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * 当某账户被授予角色时触发 发起者是 admin 角色
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * 某账户角色被取消时触发 发起者可能是 admin 角色 也可能是账户
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * 某账户是否有某角色 外部函数 只读
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * 获取能控制某角色的 admin 角色
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * 授予账户角色 调用者必须拥有 admin 角色
     * @dev Grants `role` to `account`.
     *
     * 如果账户之前没有被授予该角色，触发角色授予事件
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * 取消账户角色授权
     * @dev Revokes `role` from `account`.
     *
     * 如果账户之前拥有该角色，取消后触发角色取消事件
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     * - 调用者必须拥有 admin 角色
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * 放弃角色
     * @dev Revokes `role` from the calling account.
     *
     * 角色的管理通常通过授予角色和取消角色，这里提供方法给账户主动放弃自己的角色
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * 如果账户之前拥有该角色，取消后触发角色取消事件
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}
