from app.config.db import db

async def search_medical_knowledge_db(term: str):
    sql = """
        SELECT * FROM medical_knowledge 
        WHERE 
            keyword ILIKE $1 OR 
            $1 ILIKE ANY(conditions) OR
            source ILIKE $1
    """
    return await db.fetch_all(sql, f"%{term}%")

async def get_medical_knowledge_by_keyword(keyword: str):
    sql = 'SELECT * FROM medical_knowledge WHERE keyword ILIKE $1'
    return await db.fetch_one(sql, keyword)

async def get_emergency_records(query_text: str):
    sql = """
        SELECT * FROM medical_knowledge 
        WHERE category = 'emergency' AND $1 ILIKE ('%' || keyword || '%')
    """
    return await db.fetch_all(sql, query_text)

async def add_medical_record(data: dict):
    sql = """
        INSERT INTO medical_knowledge (
            keyword, category, severity, conditions, otc_medicines, 
            precautions, when_to_see_doctor, immediate_action, do_not, source
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING *
    """
    values = [
        data.get('keyword'),
        data.get('category', 'symptom'),
        data.get('severity', 'Low'),
        data.get('conditions', []),
        data.get('otc_medicines', []),
        data.get('precautions', []),
        data.get('when_to_see_doctor'),
        data.get('immediate_action'),
        data.get('do_not', []),
        data.get('source', 'Medical Knowledge Base')
    ]
    return await db.fetch_one(sql, *values)
