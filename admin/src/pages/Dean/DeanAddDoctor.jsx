import React, { useContext, useEffect, useState } from 'react'
import { toast } from 'react-toastify'
import axios from 'axios'
import { DeanContext } from '../../context/DeanContext'
import { useNavigate } from 'react-router-dom'
import AddDoctorForm from '../../components/AddDoctorForm'

const buildAbout = (p, years) => {
    const clean = (p.name || 'The doctor').replace(/^Dr\.?\s*/i, '')
    return `Dr. ${clean} is a ${p.qualification || 'qualified'} ${p.speciality || 'medical'} specialist with ${years} year(s) of experience${p.department ? ` in the ${p.department} department` : ''}.`
}

const DeanAddDoctor = () => {
    const { deanToken, getDoctors, hospital, getHospital } = useContext(DeanContext)
    const navigate = useNavigate()
    const [submitting, setSubmitting] = useState(false)

    const backendUrl = import.meta.env.VITE_BACKEND_URL

    useEffect(() => {
        if (deanToken && !hospital) getHospital()
    }, [deanToken])

    const onSubmit = async (p) => {
        setSubmitting(true)
        try {
            const years = parseInt(p.experience) || 1
            const { data } = await axios.post(backendUrl + '/api/dean/doctors/add', {
                name: p.name,
                email: p.email,
                password: p.password?.trim() || undefined,
                experience: `${years} Year`,
                fees: Number(p.fees) || 0,
                about: buildAbout(p, years),
                speciality: p.speciality,
                degree: p.qualification,
                address: { line1: p.address, line2: p.consultationRoom },
            }, { headers: { deantoken: deanToken } })

            if (data.success) {
                toast.success('Doctor added successfully! Credentials emailed.')
                await getDoctors()
                navigate('/dean-doctors')
                return true
            }
            toast.error(data.message || 'Failed to add doctor')
            return false
        } catch (error) {
            toast.error(error.response?.data?.message || error.message || 'Failed to add doctor')
            return false
        } finally {
            setSubmitting(false)
        }
    }

    return (
        <AddDoctorForm
            breadcrumb={`${hospital?.name || 'Hospital'} › Doctors › Add Doctors`}
            onSubmit={onSubmit}
            submitting={submitting}
        />
    )
}

export default DeanAddDoctor
