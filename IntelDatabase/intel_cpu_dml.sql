-- Victor Martinez Query 2

-- A query of your choice. You should include comments describing the use of the queries.

-- Query that Shows Processors with integrated graphics to avoid
-- Query returns processors with igpu, generation older than 9, and series below 7. Processors are older and more likely to not meet system requirements for newer software
-- ordered by cpu base clock speed, igpu speed, and series version

SELECT  
    gen_codename AS Name, 
    cpu_name AS CPU, 
    cpu.series_id AS CORE, 
    cpu_base_clock AS 'Clock Speed', 
    igpu_name AS iGPU, 
    igpu_boost_clock AS 'iGPU Speed'
FROM CPU
INNER JOIN igpu ON igpu.igpu_id = cpu.igpu_id
INNER JOIN generation ON generation.gen_id = cpu.gen_id
WHERE cpu.igpu_id > 0 AND cpu.gen_id < 9 AND cpu.series_id < 7
ORDER BY cpu_base_clock, igpu_boost_clock, cpu.series_id;

-- Ted's Query 1 - (Order By Query)
-- This query can be used to determine the slowest base clock based off of the minimum base clock and displays the CPU's generation, series, and name

SELECT cpu.gen_id AS " CPU Generation",
cpu.series_id AS "CPU Series",
cpu.cpu_name AS "CPU Name",
cpu.cpu_base_clock AS "Base Clock",
cpu.cpu_boost_clock AS "Boost Clock"
FROM CPU
ORDER BY cpu.cpu_base_clock ASC;

-- Aren's Query 1 - (A select statement that includes at least one subquery)
-- This query determines which socketType has the best 'performance'
-- It sorts by the highest CoreCount, ThreadCount, and MaxBoostClock based on the SocketType and then displays the top 6 of each SocketType
SELECT 
    SocketType,
    Generation,
    CPU,
    CoreCount,
    ThreadCount,
    BaseClock,
    MaxBoostClock
FROM (
    SELECT 
        CONCAT('LGA-', c.socket_id) AS SocketType,
        g.gen_codename AS Generation,
        CONCAT('i', s.series_id, '-', c.cpu_name) AS CPU,
        c.cpu_core_count AS CoreCount,
        c.cpu_thread_count AS ThreadCount,
        CONCAT(cpu_min_max.min_base_clock, ' GHz') AS BaseClock, -- Format and select the min base clock
        CONCAT(cpu_min_max.max_boost_clock, ' GHz') AS MaxBoostClock, -- Format and select the max base clock
        ROW_NUMBER() OVER (
            PARTITION BY CONCAT('LGA-', c.socket_id) -- Partitioning by SocketType to rank within each type
            ORDER BY c.cpu_core_count DESC, c.cpu_thread_count DESC, cpu_min_max.max_boost_clock DESC -- Ordering by CoreCount, ThreadCount, MaxBoostClock
        ) AS rn -- Assign row numbers within each partition
    FROM 
        cpu c
    INNER JOIN series s ON c.series_id = s.series_id -- Join the CPU table with Series table based on series_id
    JOIN (
        SELECT 
            gen_id,
            MAX(cpu_boost_clock) AS max_boost_clock,
            MIN(cpu_base_clock) AS min_base_clock
        FROM 
            cpu
        GROUP BY 
            gen_id
    ) AS cpu_min_max ON c.gen_id = cpu_min_max.gen_id -- Joining to get min and max clock speeds by generation
    LEFT JOIN generation g ON c.gen_id = g.gen_id -- Joining to get generation code names
) AS ranked
WHERE rn <= 6 -- Select only the top 6 CPUs within each SocketType
ORDER BY SocketType, rn; -- Ordering the results by SocketType and row number


-- Aren's Query 2 - (Query of my choice)
-- This query organizes the top end cpu's with and without igpu's for consumers to decide if iGPU's offer better performance overall.
-- It displays each generations top cpu's clock speeds with and without iGPU's within the range of clock speed 4.0 to max
SELECT 
    gen.gen_codename AS Generation, -- Selecting the generation code name
    s.socket_id AS Socket_Type, -- Selecting the socket type
    CONCAT('i', se.series_id, '-', c.cpu_name) AS CPU, -- Generating a representation of the CPU
    MAX(CASE WHEN c.igpu_id = 0 THEN CONCAT(c.cpu_boost_clock, ' GHz') END) AS CPU_Without_iGpu, -- Selecting max CPU boost clock without iGPU
    MAX(CASE WHEN c.igpu_id != 0 THEN CONCAT(c.cpu_boost_clock, ' GHz') END) AS CPU_With_iGpu -- Selecting max CPU boost clock with iGPU
FROM 
    cpu c
INNER JOIN series se ON c.series_id = se.series_id -- Joining CPU with Series based on series_id
INNER JOIN socket s ON c.socket_id = s.socket_id -- Joining CPU with Socket based on socket_id
LEFT JOIN generation gen ON c.gen_id = gen.gen_id -- Joining CPU with Generation based on gen_id
WHERE
    c.cpu_boost_clock >= 4.0 -- Filter the CPU boost clock greater than or equal to 4.0 GHz
GROUP BY 
    gen.gen_codename, s.socket_id, CONCAT('i', se.series_id, '-', c.cpu_name) -- Grouping the results by generation, socket type, and CPU representation
ORDER BY 
    gen.gen_codename DESC, -- Ordering by Generation in descending order
    MAX(CASE WHEN c.igpu_id != 0 THEN c.cpu_boost_clock ELSE 0 END) DESC, -- Ordering by max CPU boost clock with iGPU in descending order
    MAX(CASE WHEN c.igpu_id = 0 THEN c.cpu_boost_clock ELSE 0 END) DESC; -- Ordering by max CPU boost clock without iGPU in descending order


/* Show the average core count, 
and base clock speed, as well as the high/low base clock across all cpu's in a given generation, 
and the total number of CPU's in that generation 

A select statement that includes at least two aggregate functions

Charles Swick */

SELECT cpu.gen_id as "Generation", AVG(CPU.CPU_CORE_COUNT) AS "Average Core Count", 
concat(AVG(CPU.CPU_BASE_CLOCK)," GHz") as "Average base clock", 
concat(Min(cpu.cpu_base_clock)," GHz") as "Lowest Base Clock", 
concat(Max(cpu.cpu_base_clock)," GHz") as "Highest Base Clock",
COUNT(distinct CPU.CPU_ID) as "Total CPU's"
from CPU
where cpu.gen_id = 6;


/* Display all distinct CPU's from a generation that match the cache size and base clock speed
   
A select statement that uses at least one join, concatenation, and distinct clause
   
Charles Swick */
 
select distinct concat(ucase(left(gen_codename,1)),substring(gen_codename,2)) as "Generation", 
concat("LGA-",cpu.socket_id) as "Socket",
concat("Core i",cpu.series_id) as "CPU Series",cpu.cpu_name as "Processor ID",
concat(cpu.cpu_cache," MB") as "Cache", concat(cpu.cpu_base_clock," GHz") as "Base Clock",
cpu.cpu_core_count as "Total Cores", cpu.cpu_thread_count as "Total Threads"
from generation
inner join CPU on generation.gen_id = cpu.gen_id
where generation.gen_id = 13 and cpu.cpu_cache > 20 and cpu.cpu_base_clock > 2.0;


-- Cristian Lopez
-- Show all hexacore or higher CPU's with a TDP lower than the average, from 8th gen or newer
-- Sort by highest base clock rate
-- Relevance : Finding the most efficient processor to save money on electricity and to ensure adequate cooling in a given system.
Select distinct concat(concat("i",cpu.series_id),
concat("    ",cpu_name)) as "Processor",cpu_tdp as TDP, cpu_base_clock as "Base Clock"
from CPU
inner join Generation on cpu.gen_id = generation.gen_id
where cpu_tdp <= (select AVG(cpu_tdp) from cpu) and generation.gen_id >= 8 and cpu.cpu_core_count >= 6
order by cpu_base_clock desc;


-- Cristian Lopez 
-- This query can be used to determine the fastest processor available for each series
-- Displays the highest end processor for each generation based on cache size, and Core Count
-- Relevance : Example for the ASUS Prime Z390 motherboard (Intel 8th Gen) the fastest compatible processors are the 8350k, 8400, 8700

SELECT 
    Generation,
    Socket_Type,
    CPU,
    Min_Cache_Size,
    Min_Core_Count
FROM (
    SELECT 
        gen.gen_codename AS Generation,
        s.socket_id AS Socket_Type,
        CONCAT('i', se.series_id, '-', c.cpu_name) AS CPU,
        MIN(c.cpu_cache) AS Min_Cache_Size,
        MIN(c.cpu_core_count) AS Min_Core_Count,
    ROW_NUMBER() OVER (
        PARTITION BY gen.gen_codename, se.series_id -- Partition by generation and series
        ORDER BY se.series_id -- Ordering by series_id directly
        ) AS rn -- Assign row number
    FROM 
        cpu c
    INNER JOIN series se ON c.series_id = se.series_id -- Join Series table
    INNER JOIN socket s ON c.socket_id = s.socket_id -- Join Socket table
    LEFT JOIN igpu i ON c.igpu_id = i.igpu_id -- Left join iGPU
    LEFT JOIN generation gen ON c.gen_id = gen.gen_id -- Left join generation
    GROUP BY 
        gen.gen_codename, s.socket_id, se.series_id, c.cpu_name
) AS ranked
WHERE rn = 1 -- Filtering the top CPU for each generation and series
ORDER BY 
    Generation DESC,
    Min_Cache_Size ASC,
    Min_Core_Count ASC;


-- =========================================================================================
-- =                                    TRIGGER QUERIES                                    =
-- =========================================================================================


-- Victor's Query 1

-- An insert statement that runs a trigger in which the trigger adds data or updates data in a table

-- trigger activates when cpu information changes and if the base clock speed is higher than the boost, it will set both speeds to 0 to represent failure.
-- insert query will only work once, must increment first value of 113 to run again

-- trigger:

delimiter |
CREATE TRIGGER CLOCK_FIX
BEFORE INSERT ON CPU -- before inserting any new data of new cpus
FOR EACH ROW
BEGIN
    IF NEW.cpu_base_clock > NEW.cpu_boost_clock THEN -- if base speed is faster than boost
        SET NEW.cpu_boost_clock = 0.0;
            SET NEW.cpu_base_clock = 0.0; -- trigger sets base and boost to 0
    END IF;
END;
|
delimiter ;

-- Insert Query:

INSERT INTO CPU (cpu_id, cpu_name, gen_id, series_id, socket_id, cpu_date, cpu_base_clock, cpu_boost_clock, cpu_core_count, cpu_thread_count, cpu_cache, cpu_tdp, igpu_id) VALUES 
('113', '14000', '13', '9', '1700', '2024', '6', '5', '24', '32', '36', '125', '0');


-- Deletes all i3 CPU's when the 3 entry is deleted from Series
-- A delete statement that runs a trigger in which the trigger deletes data in one table.
-- Ted Lee

DROP TRIGGER IF EXISTS KILL_I3; -- Remove the trigger if it exists already to avoid errors.

DELIMITER |
CREATE TRIGGER KILL_I3
BEFORE DELETE ON SERIES
FOR EACH ROW
BEGIN
	DELETE FROM CPU WHERE CPU.SERIES_ID = 3; -- Loop through and delete all i3 CPU's from the database.
END;
| 
DELIMITER ;

-- Activates the trigger
DELETE FROM SERIES WHERE SERIES_ID = 3;