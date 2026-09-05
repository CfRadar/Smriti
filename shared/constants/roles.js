export const ROLES = Object.freeze({
  PATIENT: 'patient',
  CAREGIVER: 'caregiver',
  ADMIN: 'admin',
  NGO: 'ngo',
});

export const ROLE_PERMISSIONS = Object.freeze({
  [ROLES.PATIENT]: ['read:self', 'submit:game', 'update:reminder-status', 'sync:data'],
  [ROLES.CAREGIVER]: ['read:patient', 'manage:reminders', 'manage:memories', 'view:analytics', 'submit:assessment'],
  [ROLES.NGO]: ['read:community-patients', 'view:aggregate-analytics', 'manage:support-groups'],
  [ROLES.ADMIN]: ['manage:all', 'manage:users', 'audit:system', 'view:analytics'],
});
