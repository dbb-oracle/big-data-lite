create table MOVIEDEMO.ODI_COUNTRY_SALES (
COUNTRY_ID	NUMBER		NOT NULL,	
COUNTRY	VARCHAR2(400)		,	
CONTINENT_ID	NUMBER		,	
CONTINENT	VARCHAR2(400)		,	
TOTAL_SALES	NUMBER		 );

 alter table MOVIEDEMO.ODI_COUNTRY_SALES
	add constraint COUNTRY_PK
	primary key (COUNTRY_ID);

