import React, { useContext, useEffect, useState } from 'react'
import { toast } from 'react-toastify'
import axios from 'axios'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import AddDoctorForm, { generatePassword } from '../../components/AddDoctorForm'

const buildAbout = (p, years) => {
    const clean = (p.name || 'The doctor').replace(/^Dr\.?\s*/i, '')
    return `Dr. ${clean} is a ${p.qualification || 'qualified'} ${p.speciality || 'medical'} specialist with ${years} year(s) of experience${p.department ? ` in the ${p.department} department` : ''}.`
}

const AddDoctor = () => {
    const { backendUrl } = useContext(AppContext)
    const { aToken, getAllDoctors, getDashData } = useContext(AdminContext)
    const [submitting, setSubmitting] = useState(false)

    useEffect(() => {
        if (aToken) getAllDoctors()
    }, [aToken])

    const onSubmit = async (p) => {
        setSubmitting(true)
        try {
            const manualPass = p.password?.trim()
            const password = manualPass || generatePassword()
            const years = parseInt(p.experience) || 1

            const fd = new FormData()
            if (p.image) fd.append('image', p.image)
            fd.append('name', p.name)
            fd.append('email', p.email)
            fd.append('password', password)
            fd.append('experience', `${years} Year`)
            fd.append('fees', Number(p.fees) || 0)
            fd.append('about', buildAbout(p, years))
            fd.append('speciality', p.speciality)
            fd.append('degree', p.qualification)
            fd.append('address', JSON.stringify({ line1: p.address, line2: p.consultationRoom }))

            const { data } = await axios.post(backendUrl + '/api/admin/add-doctor', fd, { headers: { aToken } })
            if (data.success) {
                toast.success(data.message || 'Doctor added')
                if (!manualPass) {
                    toast.info(`Auto-generated password for ${p.email}: ${password}`, { autoClose: false })
                }
                getAllDoctors()
                getDashData()
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
            breadcrumb="Admin › Doctors › Add Doctors"
            onSubmit={onSubmit}
            submitting={submitting}
        />
    )
}

export default AddDoctor
