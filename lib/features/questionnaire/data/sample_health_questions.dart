import '../domain/health_question.dart';

/// Fixture copied/adapted from the SangreVital web questionnaire.
/// Replace with versioned questions returned by the Bloomi API.
const sampleHealthQuestions = <HealthQuestion>[
  HealthQuestion(
    id: 'general_read_info',
    category: 'Información general',
    prompt: '¿Has leído la información previa a la donación?',
  ),
  HealthQuestion(
    id: 'general_recent_donation',
    category: 'Información general',
    prompt: '¿Has donado sangre recientemente?',
  ),
  HealthQuestion(
    id: 'general_feeling_well',
    category: 'Información general',
    prompt: '¿Te sientes bien de salud hoy?',
  ),
  HealthQuestion(
    id: 'general_pregnancy',
    category: 'Información general',
    prompt: '¿Estás embarazada?',
  ),
  HealthQuestion(
    id: 'general_medication',
    category: 'Información general',
    prompt: '¿Estás tomando medicamentos?',
  ),
  HealthQuestion(
    id: 'general_pending_appointment',
    category: 'Información general',
    prompt: '¿Estás esperando una consulta médica?',
  ),
  HealthQuestion(
    id: 'recent_risky_activity',
    category: 'Actividades recientes',
    prompt: 'En las próximas 12 horas, ¿realizarás actividades de riesgo?',
  ),
  HealthQuestion(
    id: 'recent_fever',
    category: 'Actividades recientes',
    prompt: '¿Has tenido fiebre recientemente?',
  ),
  HealthQuestion(
    id: 'recent_dentist',
    category: 'Actividades recientes',
    prompt: '¿Has ido al dentista recientemente?',
  ),
  HealthQuestion(
    id: 'recent_specific_meds',
    category: 'Actividades recientes',
    prompt: '¿Tomas medicamentos específicos?',
  ),
  HealthQuestion(
    id: 'recent_vaccine',
    category: 'Actividades recientes',
    prompt: '¿Has sido vacunado recientemente?',
  ),
  HealthQuestion(
    id: 'recent_infectious_contact',
    category: 'Actividades recientes',
    prompt:
        '¿Has estado en contacto con personas con enfermedades infecciosas?',
  ),
  HealthQuestion(
    id: 'history_consultation',
    category: 'Historial médico',
    prompt: '¿Has tenido una consulta médica reciente?',
  ),
  HealthQuestion(
    id: 'history_procedure',
    category: 'Historial médico',
    prompt: '¿Has tenido una intervención médica reciente?',
  ),
  HealthQuestion(
    id: 'history_piercing',
    category: 'Historial médico',
    prompt: '¿Te has hecho piercings recientemente?',
  ),
  HealthQuestion(
    id: 'history_tattoo',
    category: 'Historial médico',
    prompt: '¿Te has hecho tatuajes recientemente?',
  ),
  HealthQuestion(
    id: 'history_blood_contact',
    category: 'Historial médico',
    prompt: '¿Has estado en contacto con sangre de otra persona?',
  ),
  HealthQuestion(
    id: 'history_hepatitis_contact',
    category: 'Historial médico',
    prompt: '¿Has estado en contacto con hepatitis?',
  ),
  HealthQuestion(
    id: 'history_travel',
    category: 'Historial médico',
    prompt: '¿Has viajado recientemente?',
  ),
  HealthQuestion(
    id: 'history_cjd_family',
    category: 'Historial médico',
    prompt: '¿Tienes familiares con enfermedad de Creutzfeldt-Jakob?',
  ),
  HealthQuestion(
    id: 'risk_hiv',
    category: 'Factores de riesgo',
    prompt: '¿Tienes VIH?',
  ),
  HealthQuestion(
    id: 'risk_hepatitis',
    category: 'Factores de riesgo',
    prompt: '¿Tienes hepatitis?',
  ),
  HealthQuestion(
    id: 'risk_injection_drugs',
    category: 'Factores de riesgo',
    prompt: '¿Has consumido drogas inyectadas?',
  ),
  HealthQuestion(
    id: 'risk_sex_for_payment',
    category: 'Factores de riesgo',
    prompt: '¿Has recibido dinero o pago por relaciones sexuales?',
  ),
  HealthQuestion(
    id: 'risk_partner',
    category: 'Factores de riesgo',
    prompt: '¿Has tenido una pareja sexual con factores de riesgo?',
  ),
  HealthQuestion(
    id: 'risk_sti',
    category: 'Factores de riesgo',
    prompt: '¿Tienes una infección de transmisión sexual?',
  ),
  HealthQuestion(
    id: 'risk_previous_deferral',
    category: 'Factores de riesgo',
    prompt: '¿Te han rechazado antes para donar?',
  ),
  HealthQuestion(
    id: 'risk_recent_donation',
    category: 'Factores de riesgo',
    prompt: '¿Has donado sangre en los últimos 2 meses?',
  ),
  HealthQuestion(
    id: 'risk_endoscopy',
    category: 'Factores de riesgo',
    prompt: '¿Te han realizado una endoscopia?',
  ),
  HealthQuestion(
    id: 'risk_surgery',
    category: 'Factores de riesgo',
    prompt: '¿Has tenido cirugías?',
  ),
  HealthQuestion(
    id: 'risk_acupuncture',
    category: 'Factores de riesgo',
    prompt: '¿Te han realizado acupuntura?',
  ),
  HealthQuestion(
    id: 'risk_prostate_meds',
    category: 'Factores de riesgo',
    prompt: '¿Tomas medicamentos para la próstata?',
  ),
  HealthQuestion(
    id: 'risk_birth_abroad',
    category: 'Factores de riesgo',
    prompt: '¿Naciste fuera de Colombia?',
  ),
  HealthQuestion(
    id: 'risk_uk_residence',
    category: 'Factores de riesgo',
    prompt: '¿Has vivido en el Reino Unido?',
  ),
  HealthQuestion(
    id: 'risk_serious_illness',
    category: 'Factores de riesgo',
    prompt: '¿Tienes una enfermedad grave?',
  ),
  HealthQuestion(
    id: 'risk_liver',
    category: 'Factores de riesgo',
    prompt: '¿Tienes problemas hepáticos?',
  ),
  HealthQuestion(
    id: 'risk_infectious_disease',
    category: 'Factores de riesgo',
    prompt: '¿Tienes una enfermedad infecciosa?',
  ),
  HealthQuestion(
    id: 'risk_chronic_organ',
    category: 'Factores de riesgo',
    prompt: '¿Tienes una enfermedad crónica de algún órgano?',
  ),
  HealthQuestion(
    id: 'risk_heart',
    category: 'Factores de riesgo',
    prompt: '¿Tienes problemas cardíacos?',
  ),
  HealthQuestion(
    id: 'risk_epilepsy',
    category: 'Factores de riesgo',
    prompt: '¿Tienes epilepsia?',
  ),
  HealthQuestion(
    id: 'risk_diabetes',
    category: 'Factores de riesgo',
    prompt: '¿Tienes diabetes?',
  ),
  HealthQuestion(
    id: 'risk_allergies',
    category: 'Factores de riesgo',
    prompt: '¿Tienes alergias?',
  ),
  HealthQuestion(
    id: 'risk_bleeding',
    category: 'Factores de riesgo',
    prompt: '¿Tienes trastornos de sangrado?',
  ),
  HealthQuestion(
    id: 'risk_transfusion',
    category: 'Factores de riesgo',
    prompt: '¿Has recibido transfusiones?',
  ),
];
