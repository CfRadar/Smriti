import * as patientService from '../services/patient.service.js';
import { sendSuccess, sendError } from '../utils/response.js';
import { Caregiver } from '../models/Caregiver.js';

export const getAllPatients = async (req, res, next) => {
  try {
    let query = {};

    //If caller is a caregiver, filter only their assigned patients
    if (req.user && req.user.role === 'caregiver') {
      const caregiver = await Caregiver.findOne({ userId: req.user.id });
      if (caregiver && caregiver.assignedPatients?.length > 0) {
        query = { _id: { $in: caregiver.assignedPatients } };
      } else {
        // Caregiver has no assigned patients yet, return empty or as per business logic.
        // Here we return empty list.
        return sendSuccess(res, [], 'No patients assigned yet');
      }
    }

    const patients = await patientService.getPatients(query);
    return sendSuccess(res, patients, 'Patients retrieved');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const getPatient = async (req, res, next) => {
  try {
    const patient = await patientService.getPatientById(req.params.id);
    return sendSuccess(res, patient, 'Patient retrieved');
  } catch (error) {
    return sendError(res, error.message, 404);
  }
};

export const createPatient = async (req, res, next) => {
  try {
    const patient = await patientService.createPatientProfile(req.body);
    return sendSuccess(res, patient, 'Patient created', 201);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};

export const updatePatient = async (req, res, next) => {
  try {
    const patient = await patientService.updatePatientProfile(req.params.id, req.body);
    return sendSuccess(res, patient, 'Patient updated');
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};
