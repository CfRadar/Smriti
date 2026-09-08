import React, { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import {
  Image as ImageIcon,
  Plus,
  Trash2,
  Users,
  Calendar,
  Volume2,
  X,
  AlertCircle,
  Sparkles
} from "lucide-react";
import { api } from "../../services/api";

interface AssociatedPerson {
  name: string;
  relation: string;
}

interface FamilyMemoryItem {
  _id: string;
  title: string;
  description?: string;
  mediaUrl?: string;
  associatedPeople?: AssociatedPerson[];
  eventDate?: string;
  audioPromptUrl?: string;
}

const PRESET_PHOTOS = [
  {
    title: "Diwali Family Celebration",
    name: "Aarav & Priya",
    relation: "Grandchildren",
    url: "https://images.unsplash.com/photo-1609137144822-42173f274a27?auto=format&fit=crop&w=600&q=80",
    description: "Lighting diyas with grandchildren during the festival of lights.",
  },
  {
    title: "Tea Garden Morning",
    name: "Ratan",
    relation: "Brother",
    url: "https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=600&q=80",
    description: "Walking through the Jorhat tea gardens together in the autumn mist.",
  },
  {
    title: "Family Picnic at Umiam Lake",
    name: "Sunita & Ankit",
    relation: "Daughter & Son-in-law",
    url: "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=600&q=80",
    description: "Quiet picnic near Shillong with home-cooked snacks.",
  },
];

export default function MemoriesPage() {
  const { selectedPatient, patients } = useOutletContext<{
    selectedPatient: string;
    patients: Array<{ _id: string; name?: string; userId?: { name: string } }>;
  }>();

  const [memories, setMemories] = useState<FamilyMemoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form State
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [personName, setPersonName] = useState("");
  const [relation, setRelation] = useState("");
  const [mediaUrl, setMediaUrl] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const currentPatient = patients?.find(
    (p) => (p._id || (p as unknown as { id: string }).id) === selectedPatient
  );
  const patientName = currentPatient?.userId?.name || currentPatient?.name || "Patient";

  useEffect(() => {
    if (!selectedPatient) return;
    loadMemories(selectedPatient);
  }, [selectedPatient]);

  const loadMemories = async (patientId: string) => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get(`/family/patient/${patientId}`);
      setMemories(Array.isArray(data) ? data : []);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load family memories";
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Remove this memory card from the patient's reminiscence gallery?")) return;
    try {
      await api.delete(`/family/${id}`);
      setMemories((prev) => prev.filter((m) => m._id !== id));
    } catch (err) {
      console.error("Failed to delete memory:", err);
    }
  };

  const handleCreateMemory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !selectedPatient) return;

    setSubmitting(true);
    try {
      const payload = {
        patientId: selectedPatient,
        title: title.trim(),
        description: description.trim(),
        mediaUrl: mediaUrl.trim() || PRESET_PHOTOS[0].url,
        associatedPeople: personName.trim()
          ? [{ name: personName.trim(), relation: relation.trim() || "Family Member" }]
          : [],
        eventDate: new Date().toISOString(),
      };

      const newMemory = await api.post("/family", payload);
      if (newMemory) {
        setMemories((prev) => [newMemory, ...prev]);
      }
      setIsModalOpen(false);
      resetForm();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to save memory";
      alert(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const applyPreset = (preset: (typeof PRESET_PHOTOS)[0]) => {
    setTitle(preset.title);
    setDescription(preset.description);
    setPersonName(preset.name);
    setRelation(preset.relation);
    setMediaUrl(preset.url);
  };

  const resetForm = () => {
    setTitle("");
    setDescription("");
    setPersonName("");
    setRelation("");
    setMediaUrl("");
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Family Memories & Reminiscence</h1>
          <p className="text-sm text-gray-500 mt-1">
            Photographs and personalized prompts powering face recall and memory therapy for {patientName}.
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-medium shadow-sm transition"
        >
          <Plus size={18} />
          <span>Upload Memory</span>
        </button>
      </div>

      {error && (
        <div className="p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 text-sm flex items-center gap-2">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      {/* Gallery Grid */}
      {loading ? (
        <div className="bg-white rounded-2xl border border-gray-200 p-12 text-center text-sm text-gray-400">
          Loading memory album...
        </div>
      ) : memories.length === 0 ? (
        <div className="bg-white rounded-2xl border border-dashed border-gray-300 p-12 text-center">
          <div className="w-12 h-12 bg-pink-50 text-pink-600 rounded-xl flex items-center justify-center mx-auto mb-3">
            <ImageIcon size={24} />
          </div>
          <h3 className="text-base font-semibold text-gray-900">No memories added yet</h3>
          <p className="text-xs text-gray-500 mt-1 max-w-sm mx-auto">
            Upload cherished family pictures, children's faces, and familiar places. The Smriti mobile app uses these in interactive cognitive recall games.
          </p>
          <button
            onClick={() => setIsModalOpen(true)}
            className="mt-4 px-4 py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 rounded-lg text-xs font-medium transition"
          >
            + Add First Memory
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {memories.map((mem) => {
            const firstPerson = mem.associatedPeople?.[0];
            const imageUrl = mem.mediaUrl || PRESET_PHOTOS[0].url;

            return (
              <div
                key={mem._id}
                className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-sm hover:shadow-md transition flex flex-col group"
              >
                {/* Image Preview */}
                <div className="relative h-48 bg-gray-100 overflow-hidden">
                  <img
                    src={imageUrl}
                    alt={mem.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition duration-500"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = PRESET_PHOTOS[0].url;
                    }}
                  />
                  <div className="absolute top-3 right-3">
                    <button
                      onClick={() => handleDelete(mem._id)}
                      className="p-1.5 bg-black/60 hover:bg-red-600 text-white rounded-lg backdrop-blur-sm transition"
                      title="Delete memory"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                  {firstPerson && (
                    <div className="absolute bottom-3 left-3 bg-white/90 backdrop-blur-sm px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-800 shadow-sm flex items-center gap-1.5">
                      <Users size={12} className="text-indigo-600" />
                      <span>{firstPerson.name}</span>
                      <span className="text-gray-500 font-normal">({firstPerson.relation})</span>
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="p-5 flex-1 flex flex-col justify-between">
                  <div>
                    <h3 className="text-base font-bold text-gray-900">{mem.title}</h3>
                    {mem.description && (
                      <p className="text-xs text-gray-600 mt-2 leading-relaxed">
                        {mem.description}
                      </p>
                    )}
                  </div>

                  <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
                    <div className="flex items-center gap-1">
                      <Calendar size={13} className="text-gray-400" />
                      <span>
                        {mem.eventDate
                          ? new Date(mem.eventDate).toLocaleDateString()
                          : "Photo Album"}
                      </span>
                    </div>

                    <div className="flex items-center gap-1 text-pink-600 font-medium bg-pink-50 px-2 py-0.5 rounded">
                      <Volume2 size={12} />
                      <span>AI Recall Ready</span>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal: Add Memory */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-gray-100 animate-fadeIn max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <ImageIcon size={20} className="text-indigo-600" />
                Add Family Memory
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-gray-600 p-1 rounded-lg"
              >
                <X size={18} />
              </button>
            </div>

            {/* Quick Demo Presets */}
            <div className="mt-4 p-3 rounded-xl bg-indigo-50/60 border border-indigo-100">
              <span className="text-xs font-semibold text-indigo-900 flex items-center gap-1.5 mb-2">
                <Sparkles size={14} className="text-indigo-600" />
                Quick Preset Memories (Click to Auto-fill)
              </span>
              <div className="flex flex-wrap gap-1.5">
                {PRESET_PHOTOS.map((p, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => applyPreset(p)}
                    className="px-2.5 py-1 bg-white hover:bg-indigo-100 border border-indigo-200 rounded-lg text-xs text-indigo-700 transition font-medium"
                  >
                    {p.title}
                  </button>
                ))}
              </div>
            </div>

            <form onSubmit={handleCreateMemory} className="mt-4 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                  Memory Title *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Grandson Aarav at School"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                    Person Name
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Aarav"
                    value={personName}
                    onChange={(e) => setPersonName(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                    Relationship
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Grandson, Daughter"
                    value={relation}
                    onChange={(e) => setRelation(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                  Photo URL
                </label>
                <input
                  type="url"
                  placeholder="https://images.unsplash.com/..."
                  value={mediaUrl}
                  onChange={(e) => setMediaUrl(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                  Story / Familiar Context
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. Aarav holding the silver trophy he won at the Guwahati sports festival."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full px-3.5 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none resize-none"
                />
              </div>

              <div className="pt-3 border-t border-gray-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-xl transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-medium transition shadow-sm disabled:opacity-50"
                >
                  {submitting ? "Saving..." : "Save Memory"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
