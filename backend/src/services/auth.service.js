import bcrypt from 'bcryptjs';
import { User } from '../models/User.js';
import { generateToken } from '../utils/jwt.js';

export const registerUser = async ({ name, email, password, role, phoneNumber }) => {
  const existing = await User.findOne({ email });
  if (existing) {
    throw new Error('User with this email already exists');
  }

  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);

  const user = await User.create({
    name,
    email,
    password: hashedPassword,
    role: role || 'caregiver',
    phoneNumber,
  });

  const token = generateToken({ id: user._id, role: user.role, email: user.email });
  return { user: { id: user._id, name: user.name, email: user.email, role: user.role }, token };
};

export const loginUser = async ({ email, password }) => {
  const user = await User.findOne({ email });
  if (!user) {
    throw new Error('Invalid email or password');
  }

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new Error('Invalid email or password');
  }

  const token = generateToken({ id: user._id, role: user.role, email: user.email });
  return { user: { id: user._id, name: user.name, email: user.email, role: user.role }, token };
};
