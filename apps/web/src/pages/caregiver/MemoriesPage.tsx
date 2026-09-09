import React, { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import { api } from "../../services/api";

interface PatientContext {
  selectedPatient: string;
  patients: Array<{
    _id: string;
    id?: string;
    name?: string;
    userId?: { name: string };
  }>;
}

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
}

const PRESET_PHOTOS = [
  {
    title: "Diwali Family Celebration",
    name: "Aarav & Priya",
    relation: "Grandchildren",
    url: "https://images.unsplash.com/photo-1609137144822-42173f274a27?auto=format&fit=crop&w=600&q=80",
    description: "Lighting diyas with grandchildren during the festival of lights in Guwahati.",
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
    name: "Anita & Ankit",
    relation: "Daughter & Son-in-law",
    url: "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=600&q=80",
    description: "Quiet afternoon picnic with home-cooked Assamese snacks.",
  },
];

export default function MemoriesPage() {
  const { selectedPatient, patients } = useOutletContext<PatientContext>();

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
    (p) => (p._id || p.id) === selectedPatient
  );
  const patientName =
    currentPatient?.userId?.name || currentPatient?.name || "Shri Biren Bora";

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
    <div className="w-full max-w-[1600px] mx-auto p-6 md:p-8 space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-[#8b716a] text-[11px] font-bold tracking-widest uppercase font-literata">
            <span>Reminiscence &amp; Visual Recall</span>
            <span>/</span>
            <span className="text-primary font-bold">Family Memory Bank</span>
          </div>
          <h1 className="text-[34px] font-bold text-[#2b160e] tracking-tight mt-1 font-newsreader">
            Family Memories &amp; Visual Prompts
          </h1>
          <p className="text-[15px] text-[#6e5449] font-literata">
            Photographs and familiar context prompts powering face recall and memory therapy for {patientName}.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={() => setIsModalOpen(true)}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-[20px_24px_16px_22px] bg-gradient-to-r from-[#b84b25] to-[#c85a32] text-white text-[13px] font-bold hover:from-[#a03d1c] hover:to-[#b84b25] tactile-clay-btn"
          >
            <span className="material-symbols-outlined text-[18px]">add_photo_alternate</span>
            <span>Upload Memory</span>
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 rounded-[16px_12px_14px_10px] bg-[#ffdad6] border border-[#ba1a1a]/30 text-[#93000a] text-sm flex items-center gap-2 font-medium">
          <span className="material-symbols-outlined text-[18px]">warning</span>
          <span>{error}</span>
        </div>
      )}

      {/* Gallery Grid */}
      {loading ? (
        <div className="terracotta-clay-card rounded-[28px] p-12 text-center text-sm text-[#8b716a]">
          Loading memory album...
        </div>
      ) : memories.length === 0 ? (
        <div className="terracotta-clay-card rounded-[28px] p-12 text-center border-dashed border-[#dfcfc0]">
          <div className="w-12 h-12 bg-[#ffede8] text-primary rounded-[16px_12px_14px_10px] flex items-center justify-center mx-auto mb-3">
            <span className="material-symbols-outlined text-[26px]">photo_library</span>
          </div>
          <h3 className="text-base font-bold text-[#2b160e] font-newsreader">
            No memories added yet
          </h3>
          <p className="text-xs text-[#6e5449] mt-1 max-w-sm mx-auto font-literata">
            Upload cherished family pictures, grandchildren faces, and familiar places. The Smriti mobile app uses these in interactive face recall games.
          </p>
          <button
            onClick={() => setIsModalOpen(true)}
            className="mt-4 px-4 py-2 bg-[#f5eee5] hover:bg-[#ebe0d4] text-primary rounded-[14px_10px_12px_8px] text-xs font-bold transition border border-[#dfcfc0]"
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
                className="terracotta-clay-card rounded-[28px_20px_26px_22px] overflow-hidden flex flex-col justify-between group"
              >
                {/* Image Preview */}
                <div className="relative h-52 bg-[#ebe0d4] overflow-hidden">
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
                      className="p-1.5 bg-black/60 hover:bg-[#ba1a1a] text-white rounded-full backdrop-blur-sm transition"
                      title="Delete memory"
                    >
                      <span className="material-symbols-outlined text-[16px]">delete</span>
                    </button>
                  </div>
                  {firstPerson && (
                    <div className="absolute bottom-3 left-3 bg-[#ffffff]/90 backdrop-blur-sm px-3 py-1 rounded-full text-xs font-bold text-[#2b160e] shadow-sm flex items-center gap-1.5 border border-[#dfcfc0]">
                      <span className="material-symbols-outlined text-[14px] text-primary">
                        person
                      </span>
                      <span>{firstPerson.name}</span>
                      <span className="text-[#6e5449] font-normal">({firstPerson.relation})</span>
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="p-6 flex-1 flex flex-col justify-between">
                  <div>
                    <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader">
                      {mem.title}
                    </h3>
                    {mem.description && (
                      <p className="text-xs text-[#6e5449] mt-2 leading-relaxed font-literata">
                        {mem.description}
                      </p>
                    )}
                  </div>

                  <div className="mt-4 pt-3 border-t border-[#dfcfc0]/60 flex items-center justify-between text-xs text-[#6e5449]">
                    <div className="flex items-center gap-1">
                      <span className="material-symbols-outlined text-[15px] text-[#8b716a]">
                        calendar_today
                      </span>
                      <span>
                        {mem.eventDate
                          ? new Date(mem.eventDate).toLocaleDateString()
                          : "Photo Bank"}
                      </span>
                    </div>

                    <div className="flex items-center gap-1 text-primary font-bold bg-[#ffede8] px-2.5 py-0.5 rounded-full border border-primary/20">
                      <span className="material-symbols-outlined text-[14px]">psychology</span>
                      <span>Recall Ready</span>
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
          <div className="bg-white rounded-[28px_20px_26px_22px] max-w-lg w-full p-6 shadow-2xl border border-[#dfcfc0] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#dfcfc0]/70">
              <h2 className="text-[20px] font-bold text-[#2b160e] font-newsreader flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[24px]">
                  add_photo_alternate
                </span>
                Add Family Memory
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-[#8b716a] hover:text-[#2b160e] p-1 rounded-full hover:bg-[#f5eee5]"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            {/* Quick Demo Presets */}
            <div className="mt-4 p-3.5 rounded-[16px_12px_14px_10px] bg-[#f5eee5] border border-[#dfcfc0]">
              <span className="text-xs font-bold text-secondary flex items-center gap-1.5 mb-2">
                <span className="material-symbols-outlined text-[16px] text-primary">auto_awesome</span>
                Quick Preset Memories (Click to Auto-fill)
              </span>
              <div className="flex flex-wrap gap-1.5">
                {PRESET_PHOTOS.map((p, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => applyPreset(p)}
                    className="px-2.5 py-1 bg-white hover:bg-[#ebe0d4] border border-[#dfcfc0] rounded-[10px] text-xs text-primary transition font-bold"
                  >
                    {p.title}
                  </button>
                ))}
              </div>
            </div>

            <form onSubmit={handleCreateMemory} className="mt-4 space-y-4 font-literata">
              <div>
                <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                  Memory Title *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Grandson Aarav at Tezpur College"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                    Person Name
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Aarav"
                    value={personName}
                    onChange={(e) => setPersonName(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                    Relationship
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Grandson, Daughter"
                    value={relation}
                    onChange={(e) => setRelation(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                  Photo URL
                </label>
                <input
                  type="url"
                  placeholder="https://images.unsplash.com/..."
                  value={mediaUrl}
                  onChange={(e) => setMediaUrl(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                  Story / Familiar Context
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. Aarav holding the silver trophy he won at the Guwahati sports festival."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full px-3.5 py-2 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2] resize-none"
                />
              </div>

              <div className="pt-3 border-t border-[#dfcfc0]/70 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-sm text-[#6e5449] hover:bg-[#f5eee5] rounded-[14px] transition font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-gradient-to-r from-[#b84b25] to-[#c85a32] text-white rounded-[16px_20px_14px_18px] text-sm font-bold transition shadow-sm disabled:opacity-50 tactile-clay-btn"
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
