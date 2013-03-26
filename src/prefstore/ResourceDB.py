'''    
Created on 12 April 2011
@author: jog
'''

import MySQLdb
import ConfigParser
import hashlib
import logging
import base64
import random
import time
import datetime
import random

log = logging.getLogger( "console_log" )


#///////////////////////////////////////


def safety_mysql( fn ) :
    """ I have included this decorator because there are no 
    gaurantees the user has mySQL setup so that it won't time out. 
    If it has, this function remedies it, by trying (one shot) to
    reconnect to the database.
    """

    def wrapper( self, *args, **kwargs ) :
        try:
            return fn( self, *args, **kwargs )
        except MySQLdb.Error, e:
            if e[ 0 ] == 2006:
                self.reconnect()
                return fn( self, *args, **kwargs )
            else:
                raise e   
    return wrapper


#///////////////////////////////////////


class ResourceDB(object):
    ''' classdocs '''
    
    #///////////////////////////////////////
    
    def __init__( self, configfile, section, name = "ResourceDB" ):
            
        #MysqlDb is not thread safe, so program may run more
        #than one connection. As such naming them is useful.
        self.name = name
        self.CONFIG_FILE = configfile
        self.SECTION_NAME = section
        
        Config = ConfigParser.ConfigParser()
        Config.read( self.CONFIG_FILE )
        self.hostname = Config.get( self.SECTION_NAME, "hostname" )
        self.username =  Config.get( self.SECTION_NAME, "username" )
        self.password =  Config.get( self.SECTION_NAME, "password" )
        self.DB_NAME = Config.get( self.SECTION_NAME, "dbname" )
        
        self.connected = False;
        
        self.TBL_TERM_URLS = 'urls'
        self.TBL_TERM_POWER = 'energy'  
        
    
         #///////////////////////////////////////
    
        self.createQueries = [ 
                   
            ( self.TBL_TERM_URLS, """
                CREATE TABLE %s.%s (
                    id int NOT NULL AUTO_INCREMENT,
                    ts varchar(20), 
                    macaddr varchar(19), 
                    ipaddr varchar(16), 
                    url varchar(128),
                    PRIMARY KEY (id)
                ) DEFAULT CHARSET=latin1;
            """  % ( self.DB_NAME , self.TBL_TERM_URLS ) ),
           
            ( self.TBL_TERM_POWER, """ 
                CREATE TABLE %s.%s (
                    id int NOT NULL AUTO_INCREMENT,
                    ts varchar(20) NOT NULL,
                    sensorid int(11),
                    watts float,
                    PRIMARY KEY (id)
                ) DEFAULT CHARSET=latin1;
            """  % ( self.DB_NAME , self.TBL_TERM_POWER ) ),            
        ] 
        
    #///////////////////////////////////////
    
        
    def connect( self ):
        
        log.debug( "%s: connecting to mysql database..." % self.name )

        self.conn = MySQLdb.connect( 
            host=self.hostname,
            user=self.username,
            passwd=self.password,
            db=self.DB_NAME
        )
 
        self.cursor = self.conn.cursor( MySQLdb.cursors.DictCursor )
        self.connected = True
                    
                    
    #///////////////////////////////////////
    
    
    def reconnect( self ):
        
        log.debug( "%s: Database reconnection process activated..." % self.name );
        self.close()
        self.connect()
        

    #///////////////////////////////////////
          
    
    @safety_mysql
    def commit( self ) : 
        self.conn.commit();
        
        
    #///////////////////////////////////////
        
          
    def close( self ) :   
        if self.conn.open:
            log.debug( "%s: disconnecting from mysql database..." % self.name );
            self.cursor.close();
            self.conn.close();
                
                       
    #/////////////////////////////////////////////////////////////////////////////////////////////
    
    
    @safety_mysql
    def check_tables( self ):
        
        log.info( "%s: checking system table integrity..." % self.name );
        
        #-- first check that the database itself exists        
        self.cursor.execute ( """
            SELECT 1
            FROM information_schema.`SCHEMATA`
            WHERE schema_name='%s'
        """ % self.DB_NAME )
                
        row = self.cursor.fetchone()

        if ( row is None ):
            log.info( "%s: database does not exist - creating..." % self.name );    
            self.cursor.execute ( "CREATE DATABASE IF NOT EXISTS catalog" )
        
        
        #-- then check it is populated with the required tables            
        self.cursor.execute ( """
            SELECT table_name
            FROM information_schema.`TABLES`
            WHERE table_schema='%s'
        """ % self.DB_NAME )
        
        tables = [ row[ "table_name" ].lower() for row in self.cursor.fetchall() ]
 
        #if they don't exist for some reason, create them.    
        for item in self.createQueries:
            if not item[ 0 ].lower() in tables : 
                log.warning( "%s: Creating missing system table: '%s'" % ( self.name, item[ 0 ] ) );
                self.cursor.execute( item[ 1 ] )

        self.commit();
    
        
    #/////////////////////////////////////////////////////////////////////////////////////////////
    @safety_mysql
    def execute_query(self, query, parameters=None):
        log.info("*********************")
        log.info("query is %s" % query)
        log.info("parameters are")
        log.info(parameters)
        log.info("**********************")
        
        if parameters is not None:
            self.cursor.execute(query, parameters)
        else:
            self.cursor.execute( query )
        
        log.info(self.cursor._executed)
            
        row = self.cursor.fetchall()

        if not row is None:
            return row
        else :
            return None    
    
    
    @safety_mysql                
    def fetch_urls( self) :
        
        query = """
            SELECT * FROM %s.%s 
        """  % ( self.DB_NAME, self.TBL_TERM_URLS) 
   
	
        self.cursor.execute( query )
        row = self.cursor.fetchall()

        if not row is None:
            return row
        else :
            return None

    @safety_mysql
    def fetch_tables(self):
        query = """
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_type = 'BASE TABLE' AND table_schema = '%s'
                    ORDER BY 1 ASC
        """ % (self.DB_NAME)
        self.cursor.execute( query )                    
      
        tables = [ row[ "table_name" ].lower() for row in self.cursor.fetchall() ]
        return tables
        
    @safety_mysql
    def fetch_schema(self, table):
        query = """
                            SELECT column_name, data_type, is_nullable, character_maximum_length, numeric_precision 
                            FROM information_schema.COLUMNS 
                            WHERE table_name='%s' 
                            AND table_schema = '%s'
                            """ % (table, self.DB_NAME)
        self.cursor.execute( query )                    
        results = self.cursor.fetchall()
        return results
        
    #/////////////////////////////////////////////////////////////////////////////////////////////
    @safety_mysql                
    def fetch_url_count( self) :

        query = """
            SELECT url, count(url) as requests, group_concat(distinct(macaddr)) as macaddrs, group_concat(distinct(ipaddr)) as ipaddrs FROM %s.%s GROUP BY url ORDER BY requests DESC
        """  % ( self.DB_NAME, self.TBL_TERM_URLS) 
   
       
	    
        self.cursor.execute( query )
        row = self.cursor.fetchall()
       
        if not row is None:
            return row
        else :
            return None
    
    @safety_mysql
    def fetch_latest(self, table, columns, limit=100, key=None, latest=None):
        clause = ""
        
        if key and latest:
            clause = 'WHERE %s > %d' % (key,latest)
        elif key:
            clause = 'ORDER BY %s DESC' % key    
        
        query = """
            SELECT %s FROM %s.%s %s LIMIT %d
        """ % (columns, self.DB_NAME, table, clause, limit)
        
        print "query is %s " % query
        self.cursor.execute( query )
        row = self.cursor.fetchall()
        
        if not row is None:
            return row
        else :
            return None
 
    @safety_mysql
    def fetch_data(self, table, columns, limit=100, orderby=None, order=None):
        ordersql = ""
        
        if orderby and order:
            ordersql = "ORDER BY %s %s" % (orderby, order)
            
        query = """
            SELECT %s FROM %s.%s %s LIMIT %d
        """ % (columns, self.DB_NAME, table, ordersql, limit)
        
        print "query is %s " % query
        self.cursor.execute( query )
        row = self.cursor.fetchall()
       
        if not row is None:
            return row
        else :
            return None
            
    @safety_mysql
    def insert_test_record(self):
        random.seed(time.time())
        sensorid = random.randint(1,2) 
        tsnow = time.time()
        
       
        query = """
                    INSERT INTO %s.%s (ts,sensorid,watts) VALUES ('%s', %d, %2.f)
                 """  % ( self.DB_NAME, self.TBL_TERM_POWER, datetime.datetime.fromtimestamp(tsnow).strftime('%Y/%m/%d:%H:%M:%S'), sensorid,random.random() * 2000)
        
        self.cursor.execute( query )        
                 
    @safety_mysql
    def create_test_data(self):
    
        urls = ["http://www.google.com", "http://news.bbc.co.uk", "http://www.microsoft.com", "http://news.ycombinator.com", "http://www.yahoo.com", "http://nottingham.ac.uk"]
        
        macaddrs = ["3c:07:54:28:20:c2", "3c:07:54:28:20:c8", "3c:07:54:28:20:a2", "3c:07:74:78:20:c2"]
        
        ipaddrs  = ["192.168.22.33", "255.255.67.67", "123.34.56.78", "192.176.77.88"]
        
        random.seed(time.time())
    
        #start a week ago
        sensorids     = [1, 2] 
        tsnow         = time.time()
        tsthen        = time.time() - (7*24*60*60)
        
        for sensorid in sensorids:
            tstamp = tsthen
            while tstamp < tsnow:
                query = """
                    INSERT INTO %s.%s (ts,sensorid,watts) VALUES ('%s', %d, %2.f)
                 """  % ( self.DB_NAME, self.TBL_TERM_POWER, datetime.datetime.fromtimestamp(tstamp).strftime('%Y/%m/%d:%H:%M:%S'), sensorid,random.random() * 2000)
              
                self.cursor.execute( query ) 
                tstamp += (30 * 60)
        
        
        #and urls
        tsnow         = time.time()
        tsthen        = time.time() - (7*24*60*60)
        tstamp = tsthen
        
        while tstamp < tsnow:
            query = """
                    INSERT INTO %s.%s (ts,macaddr,ipaddr,url) VALUES ('%s', '%s', '%s', '%s')
                 """  % ( self.DB_NAME, self.TBL_TERM_URLS, datetime.datetime.fromtimestamp(tstamp).strftime('%Y/%m/%d:%H:%M:%S'), macaddrs[random.randint(0, len(macaddrs) - 1)], ipaddrs[random.randint(0, len(ipaddrs) - 1)], urls[random.randint(0, len(urls) - 1)])
              
            self.cursor.execute( query ) 
            tstamp += (30 * 60)
            
            
            
            