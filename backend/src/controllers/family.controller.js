import { FamilyMemory } from '../models/FamilyMemory.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getMemories = async (req, res, next) => {
  try {
    const memories = await FamilyMemory.find({ patientId: req.params.patientId });
    return sendSuccess(res, memories, 'Family memories retrieved');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const addMemory = async (req, res, next) => {
  try {
    const memory = await FamilyMemory.create(req.body);
    return sendSuccess(res, memory, 'Family memory added', 201);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};

export const deleteMemory = async (req, res, next) => {
  try {
    await FamilyMemory.findByIdAndDelete(req.params.id);
    return sendSuccess(res, null, 'Memory removed');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
