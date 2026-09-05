export const isEmail = (email) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(String(email).toLowerCase());
};

export const isNotEmpty = (val) => {
  return val !== undefined && val !== null && String(val).trim().length > 0;
};

export const isValidMongoId = (id) => {
  const re = /^[0-9a-fA-F]{24}$/;
  return re.test(String(id));
};
