import { Patient } from '../models/Patient.js';
import { User } from '../models/User.js';

export const getPatients = async (query = {}) => {
  return Patient.find(query).populate('userId', 'name email phoneNumber profileImage').populate('caregiverId');
};

export const getPatientById = async (id) => {
  const patient = await Patient.findById(id).populate('userId', 'name email phoneNumber profileImage').populate('caregiverId');
  if (!patient) throw new Error('Patient not found');
  return patient;
};

export const createPatientProfile = async (data) => {
  return Patient.create(data);
};

export const updatePatientProfile = async (id, updates) => {
  const patient = await Patient.findByIdAndUpdate(id, updates, { new: true });
  if (!patient) throw new Error('Patient not found');
  return patient;
};
