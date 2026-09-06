import React from 'react';
import { Link } from 'react-router-dom';

export const LandingPage: React.FC = () => {
    return (
        <div style={{
            display: 'flex',
            flexDirection: 'column',
            minHeight: '100vh',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '2rem',
            textAlign: 'center',
            background: 'radial-gradient(circle at 50% 20%, #1e293b 0%, #090d16 100%)'
        }}>
            <div style={{
                maxWidth: '800px',
                background: 'rgba(30, 41, 59, 0.7)',
                backdropFilter: 'blur(12px)',
                borderRadius: '24px',
                padding: '3rem',
                border: '1px solid rgba(255, 255, 255, 0.1)',
                boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)'
            }}>
                <div style={{
                    display: 'inline-block',
                    padding: '0.5rem 1.25rem',
                    borderRadius: '9999px',
                    background: 'rgba(56, 189, 248, 0.1)',
                    color: '#38bdf8',
                    fontSize: '0.875rem',
                    fontWeight: 600,
                    marginBottom: '1.5rem',
                    letterSpacing: '0.05em'
                }}>
                    SMRITI ECOSYSTEM
                </div>
                <h1 style={{ fontSize: '2.5rem', fontWeight: 800, marginBottom: '1rem', color: '#f8fafc' }}>
                    Cognitive Care Portal
                </h1>
                <p style={{ color: '#94a3b8', fontSize: '1.125rem', lineHeight: 1.6, marginBottom: '2.5rem' }}>
                    Unified dashboard for Caregivers, Administrators, and NGO Partners to monitor cognitive health, schedule reminders, and track therapy progress.
                </p>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>

                    {/* Clickable Caregiver Portal Card */}
                    <Link to="/caregiver" style={{
                        background: 'rgba(37, 99, 235, 0.2)',
                        padding: '1.5rem',
                        borderRadius: '16px',
                        border: '1px solid rgba(56, 189, 248, 0.3)',
                        display: 'block',
                        transition: 'all 0.2s',
                        cursor: 'pointer'
                    }}>
                        <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '0.5rem', color: '#38bdf8' }}>
                            Caregiver Hub &rarr;
                        </h3>
                        <p style={{ fontSize: '0.875rem', color: '#94a3b8' }}>
                            Patient daily tracking, reminders, and memory uploads.
                        </p>
                    </Link>

                    <div style={{
                        background: 'rgba(15, 23, 42, 0.6)',
                        padding: '1.5rem',
                        borderRadius: '16px',
                        border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}>
                        <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '0.5rem' }}>Admin Console</h3>
                        <p style={{ fontSize: '0.875rem', color: '#94a3b8' }}>Platform metrics, clinical assessments, and user access.</p>
                    </div>

                    <div style={{
                        background: 'rgba(15, 23, 42, 0.6)',
                        padding: '1.5rem',
                        borderRadius: '16px',
                        border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}>
                        <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '0.5rem' }}>NGO Network</h3>
                        <p style={{ fontSize: '0.875rem', color: '#94a3b8' }}>Community outreach, caregiver training, and volunteer support.</p>
                    </div>

                </div>
            </div>
        </div>
    );
};

export default LandingPage;
