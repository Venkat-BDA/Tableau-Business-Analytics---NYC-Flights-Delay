LIBNAME nyc "C:\Users\vjayanarasimhan\OneDrive - IESEG\Venkat_Jayanarasimhan\MSc Big Data Analytics For Business
\1 Course Modules\1 Semester\05 Business Reporting Tools\BRT_Group Project_Tableau\NYC flights -20201030";

/* One BIG Merge */

PROC SQL;

CREATE TABLE nyc.BigMerge as
	SELECT DISTINCT a.carrier as CarrierName, a.name as Airlines,
					
					ap.name as AirportName,

					f.origin as OriginAirport, f.dest as DestinationAirport,

					f.month as Month, f.day as Day, f.hour as Hour, f.flight as Flight, f.distance as TravelDistance,
					
					f.dep_delay as DepartureDelay, f.arr_delay as ArrivalDelay,
					sum(f.dep_delay) + sum(f.arr_delay)as TotalDelay,
					 
					w.temp as Temperature, w.dewp as DewPoint, w.humid as RelativeHumidity,
		   			w.wind_dir as WindDirection, w.wind_speed as WindSpeed, w.wind_gust as WindGustSpeed,
		   			w.precip as Precipitation, w.pressure as Pressure, w.visib as Visbility,

					p.year as FlightManufactureYear, p.type as FlightType, p.manufacturer as FlightManufacturer,
		   			p.model as FlightModel, p.engines as No_Of_Engines, p.speed as AvgCruiseSpeed,
					p.engine as EngineType

	FROM nyc.AIRLINES as a,
		 nyc.FLIGHTS as f,
		 NYC.WEATHER as w,
		 NYC.AIRPORTS as ap,
		 NYC.PLANES as p 

	WHERE a.carrier = f.carrier and
		  f.time_hour = w.time_hour and
		  f.origin = w.origin and
		  ap.faa = f.origin and
		  f.tailnum = p.tailnum

	GROUP BY 1,2,3,4,5,6,7,8,9

	ORDER BY 1;

RUN;



/* 1. Evaluating the delays for the different airlines */

PROC SQL;

drop view nyc.airlines_delay;

CREATE TABLE nyc.airlines_delay as
	SELECT a.carrier as CarrierName, a.name as Airlines, avg(dep_delay) as DepartureDelay,
		   avg(arr_delay) as ArrivalDelay, avg(dep_delay) + avg(arr_delay) as TotalDelay
	FROM nyc.AIRLINES as a, nyc.FLIGHTS as f
	WHERE a.carrier = f.carrier
	GROUP BY 1,2
	ORDER BY 5 DESC;

RUN;

/* 2. Evaluating the delays depending on the destination airports and distances */

PROC SQL;

drop view nyc.destination_delay;

CREATE TABLE nyc.destination_delay as
	SELECT DISTINCT a.carrier as CarrierName, a.name as Airlines, f.origin as OriginAirport,
		 		    f.dest as DestinationAirport, f.distance as TravelDistance, sum(dep_delay) as DepartureDelay,
		   			sum(arr_delay) as ArrivalDelay, sum(dep_delay) + sum(arr_delay)as TotalDelay
	FROM nyc.AIRLINES as a, nyc.FLIGHTS as f
	WHERE a.carrier = f.carrier
	GROUP BY 1,2,3,4
	ORDER BY 7 DESC;

RUN;

/* 3a. Departure - Evaluating reasons for delays */

PROC SQL;

drop view nyc.departure_delay;

CREATE TABLE nyc.departure_delay as
	SELECT a.carrier as CarrierName, a.name as Airlines, w.time_hour as Time, f.origin as Origin,
	       ap.name as DepartureAirport, f.dest as Destination,
		   f.dep_delay as DepartureDelay,
		   w.temp as Temperature, w.dewp as DewPoint, w.humid as RelativeHumidity,
		   w.wind_dir as WindDirection, w.wind_speed as WindSpeed, w.wind_gust as WindGustSpeed,
		   w.precip as Precipitation, w.pressure as Pressure, w.visib as Visbility,
		   p.year as FlightManufactureYear, p.type as FlightType, p.manufacturer as FlightManufacturer,
		   p.model as FlightModel, p.engines as No_Of_Engines, p.speed as AvgCruiseSpeed, p.engine as EngineType
	FROM NYC.AIRLINES as a, NYC.FLIGHTS as f, NYC.WEATHER as w, NYC.AIRPORTS as ap, NYC.PLANES as p   
	WHERE a.carrier = f.carrier and f.time_hour = w.time_hour and f.origin = w.origin and ap.faa = f.origin and
		  f.tailnum = p.tailnum
	GROUP BY 1,2,3,4,5,6
	ORDER BY 7 DESC;

RUN;

/* 3b. Arrival - Evaluating reasons for delays */

PROC SQL;

drop view nyc.arrival_delay;

CREATE TABLE nyc.arrival_delay as
	SELECT a.carrier as CarrierName, a.name as Airlines, w.time_hour as Time, f.origin as Origin,
	       f.dest as Destination, ap.name as ArrivalAirport,
		   f.dep_delay as DepartureDelay,
		   w.temp as Temperature, w.dewp as DewPoint, w.humid as RelativeHumidity,
		   w.wind_dir as WindDirection, w.wind_speed as WindSpeed, w.wind_gust as WindGustSpeed,
		   w.precip as Precipitation, w.pressure as Pressure, w.visib as Visbility,
		   p.year as FlightManufactureYear, p.type as FlightType, p.manufacturer as FlightManufacturer,
		   p.model as FlightModel, p.engines as No_Of_Engines, p.speed as AvgCruiseSpeed, p.engine as EngineType
	FROM NYC.AIRLINES as a, NYC.FLIGHTS as f, NYC.WEATHER as w, NYC.AIRPORTS as ap, NYC.PLANES as p   
	WHERE a.carrier = f.carrier and f.time_hour = w.time_hour and f.origin = w.origin and ap.faa = f.dest and
		  f.tailnum = p.tailnum
	GROUP BY 1,2,3,4,5,6
	ORDER BY 7 DESC;

RUN;

/* 4. Changes in delays over time (Month, Day & Hour) */

PROC SQL;

drop view nyc.delay_over_time;

CREATE TABLE nyc.delay_over_time as
SELECT ap.name as AirportName, a.carrier as CarrierName, a.name as AirlinesName, f.month as Month, f.day as Day, f.hour as Hour,
	   count(f.flight) as No_Of_Flights, avg(f.dep_delay) as DepartureDelay, avg(f.arr_delay) as ArrivalDelay,
	   avg(f.dep_delay) + avg(f.arr_delay) as AverageDelay
FROM NYC.airports as ap, NYC.AIRLINES as a, NYC.FLIGHTS as f
WHERE a.carrier = f.carrier and ap.faa = f.origin
GROUP BY 1,2,3,4,5,6
ORDER BY 1 ASC, 4 ASC;

RUN;

/* 5. Plot the worst routes (routes with highest delays) */

PROC SQL;

drop view nyc.worst_routes;

CREATE TABLE nyc.worst_routes as
SELECT DISTINCT f.origin as DepartureAirport, f.dest as ArrivalAirport, f.carrier as CarrierName, count(f.flight) as TotalFlights,
	            avg(f.dep_delay) + avg(f.arr_delay) as AverageDelay,
				sum(f.dep_delay) + sum(f.arr_delay) as TotalDelay
FROM NYC.FLIGHTS as f
GROUP BY 1,2
ORDER BY 1,2;

RUN;

