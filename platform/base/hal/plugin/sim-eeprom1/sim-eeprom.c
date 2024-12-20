#include PLATFORM_HEADER
#include "stack/include/ember.h"
#include "stack/include/error.h"
#include "hal/hal.h"
#include "serial/serial.h"

#include "hal/plugin/sim-eeprom/sim-eeprom.h"

#ifdef CORTEXM3
  //On the Cortex-M3 chips we define a variable that holds the actual
  //SimEE storage and then place this storage at the proper location
  //in the linker.
  #ifdef EMBER_TEST
    uint8_t simulatedEepromStorage[SIMEE_SIZE_B];
  #else //EMBER_TEST
    VAR_AT_SEGMENT(NO_STRIPPING uint8_t simulatedEepromStorage[SIMEE_SIZE_B], __SIMEE__);
  #endif //EMBER_TEST
  //sim-eeprom-internal.c uses a set of defines that parameterize its behavior.
  //Since the -internal file is precompiled, we must externally define the
  //parameters (as constants) so an application build can alter them.
  const uint8_t REAL_PAGES_PER_VIRTUAL = ((SIMEE_SIZE_HW/FLASH_PAGE_SIZE_HW)/2);
  const uint16_t REAL_PAGE_SIZE = FLASH_PAGE_SIZE_HW;
  const uint16_t LEFT_BASE = SIMEE_BASE_ADDR_HW;
  const uint16_t LEFT_TOP = ((SIMEE_BASE_ADDR_HW + (FLASH_PAGE_SIZE_HW *
                          ((SIMEE_SIZE_HW / FLASH_PAGE_SIZE_HW) / 2))) - 1);
  const uint16_t RIGHT_BASE = (SIMEE_BASE_ADDR_HW + (FLASH_PAGE_SIZE_HW *
                            ((SIMEE_SIZE_HW / FLASH_PAGE_SIZE_HW) / 2)));
  const uint16_t RIGHT_TOP = (SIMEE_BASE_ADDR_HW + (SIMEE_SIZE_HW - 1));
  const uint16_t ERASE_CRITICAL_THRESHOLD = (SIMEE_SIZE_HW / 4);
#endif //CORTEXM3

const uint16_t ID_COUNT = TOKEN_COUNT;

#define DEFINETOKENS
//Manufacturing tokens do not exist in the SimEEPROM -define to nothing
#define TOKEN_MFG(name,creator,iscnt,isidx,type,arraysize,...)

//Fundamental limitations of the Simulated EEPROM design:
//These limitations are forcefully enforced via compile-time errors
//in the declarations that follow because exceeding any of them will
//cause fatal operation and data corruption.
//(1) The maximum number of tokens that can be stored is 254.
//    (Tokens are identified by one-byte values, with 0xFF as invalid.)
//(2) The maximum size, in bytes, of a token (element) is 254.
//    (One byte, with 0xFF as invalid)
//(3) The maximum number of elements in an indexed token is 126.
//    (One byte, with MSB used as counter flag and 0x7F as non-indexed size.)
//(4) The maximum total storage for tokens plus management is SIMEE_BTS_SIZE_B/2.
//    (This limit is due to a Virtual Page only being a limited size and for
//     the Simulated EEPROM to operate with any kind of efficiency, the
//     Base Storage must be small enough to leave room for token copies.)

//If the arraysize is exactly 1, we need only a single entry in the ptrCache
//to hold this entry.  If the arraysize is not 1, we need +1 to hold
//the redirection entry in the Primary Table and then arraysize entries in
//the indexed table.  This works for all values of arraysize.
#define TOKEN_DEF(name,creator,iscnt,isidx,type,arraysize,...) \
  + (((arraysize) < 127/*fundamental limit (3)*/)                \
     ? ((arraysize) + (((arraysize)==1) ? 0 : 1))                  \
     : -10000/*force negative array length compile-time error*/)
  //value of all index counts added together
  const uint16_t PTR_CACHE_SIZE = ( 0
    #include "stack/config/token-stack.h"
  );
  //the ptrCache definition - used to provide efficient access, based upon
  //ID and index, to the freshest data in the Simulated EEPROM.
  uint16_t ptrCache[ 0 //Compiler error here means too many elements in an array token
    #include "stack/config/token-stack.h"
  ];
#undef TOKEN_DEF

//*totalTokenStorage notes the initial allocation of token data words
//in the flash virtual page. It is checked against the limit
//SIMEE_BTS_SIZE_B/2.
#define TOKEN_DEF(name,creator,iscnt,isidx,type,arraysize,...) \
  + ((arraysize) * (1/*info word*/ + BYTES_TO_WORDS(sizeof(type)) \
                  + ((!!(iscnt)) * BYTES_TO_WORDS(COUNTER_TOKEN_PAD))))
  const uint32_t totalTokenStorage[(0 //Compiler error here means total token storage exceeds limit
    + (TOKEN_COUNT*2) 
    #include "stack/config/token-stack.h"
    ) <= (SIMEE_BTS_SIZE_B/2)/*fundamental limit (4)*/
    ? 1 : -1/*negative forces compile-time error*/
  ] = { (TOKEN_COUNT*2)
    #include "stack/config/token-stack.h"
  };
#undef TOKEN_DEF

//The Size Cache definition.  Links the token to its internal storage size
//for efficient calculations.  Indexed by compile ID.  Size is in words.
//This Cache should be used for all size calculations.  halInternalSimEeStartup
//will guarantee that the compiled sizes defining this cache match the
//stored sizes.
//NOTE: All counter tokens have the COUNTER_TOKEN_PAD
//      added to provide room for the incremarks.
#define TOKEN_DEF(name,creator,iscnt,isidx,type,arraysize,...) \
  + ((sizeof(type) < 255/*fundamental limit (2)*/)             \
     ? 1 : -10000/*large negative will force compile-time error*/)
  const uint8_t sizeCache[ 0 //Compiler error here means a token's size is too large
    #include "stack/config/token-stack.h"
  ] = {
#undef TOKEN_DEF
#define TOKEN_DEF(name,creator,iscnt,isidx,type,arraysize,...) \
  (BYTES_TO_WORDS(sizeof(type))                                \
   + ((iscnt) ? BYTES_TO_WORDS(COUNTER_TOKEN_PAD) : 0)),
    #include "stack/config/token-stack.h"
  };
#undef TOKEN_DEF

#undef TOKEN_MFG
#undef DEFINETOKENS

EmberStatus halInternalSimEeStartupCore(bool forceRebuildAll, 
                                        uint8_t *lookupCache);

//This function is called before startup core.  It will check
//the flash to see if SimEE version 2 already exists in the flash.  If found,
//it will assert.  The purpose of this check is to assist developers
//by catching an accidental downgrade.
//There is no downgrade path, but users of SimEE2 might accidentally load
//a system that was built for SimEE1 use onto a chip that already had SimEE2.
//The check for existence can be ignored if a chip really wants to be
//downgraded knowing all SimEE based token data will be lost.
//The other option is to load an image that explicitely has SimEE set to
//0xFFF, or just a mass erase of the chip first.
bool checkForSimEe2DataExistence(uint32_t simEe2offset);


// A destructive downgrade doesn't check for SimEE2.
// The unit test performs its own check for SimEE2.
#if defined(DESTRUCTIVE_SIMEE2TO1_DOWNGRADE) \
    || defined(SIM_EEPROM_TEST)
static void checkForSimEe2(void)
{
}
#else
static void checkForSimEe2(void)
{
  bool simEe2Found = false;
  //These are the offsets from where SimEE1 is stored down to where
  //SimEE2 Virtual Page A, Page B, and Page C are stored.
  //These values are subtracted off of simulatedEepromStorage[] to get the
  //locations of where SimEE2's use of simulatedEepromStorage[] would be.
  //Instead of using a for loop, by calling the check for each address
  //if an assert occurs it will help the developer know exactly which Virtual
  //Page was found.
  //The the prototype for this function at the top of this file for more
  //information.
#ifdef EMBER_SIMEE1_4KB
  simEe2Found = checkForSimEe2DataExistence(0x8000);
  assert(simEe2Found == false);
  simEe2Found = checkForSimEe2DataExistence(0x5000);
  assert(simEe2Found == false);
  simEe2Found = checkForSimEe2DataExistence(0x2000);
  assert(simEe2Found == false);
#else //EMBER_SIMEE1_8KB
  simEe2Found = checkForSimEe2DataExistence(0x7000);
  assert(simEe2Found == false);
  simEe2Found = checkForSimEe2DataExistence(0x4000);
  assert(simEe2Found == false);
  simEe2Found = checkForSimEe2DataExistence(0x1000);
  assert(simEe2Found == false);
#endif
}
#endif


EmberStatus halInternalSimEeStartup(bool forceRebuildAll)
{
  // lookupCache must be declared here, outside the library so that it can
  //  be appropriately sized based on the number of tokens the application
  //  uses.
  uint8_t lookupCache[ 0 //Compiler error here means too many tokens declared
                    + (TOKEN_COUNT < 255/*fundamental limit (1)*/
                       ? TOKEN_COUNT : -1/*force compile-time error*/) ];
  uint8_t i;
  uint32_t indexSkip = TOKEN_COUNT;
  
  //The value 0xFF is used as a trigger in both caches to indicate an
  //uninitialized entry.  Unitialized entries (i.e. missing tokens) will
  //trigger repairing.
  MEMSET(lookupCache, 0xFF, ID_COUNT);
  MEMSET(ptrCache, 0xFF, PTR_CACHE_SIZE*sizeof(uint16_t));
  
  for(i = 0; i < TOKEN_COUNT; i++) {
    uint32_t size = BYTES_TO_WORDS(tokenSize[i]);
    uint32_t arraySize = tokenArraySize[i];
    if(tokenIsCnt[i])
      size += BYTES_TO_WORDS(COUNTER_TOKEN_PAD);

    emberDebugPrintf("Creator: 0x%2X, Words: %d\n",
                     tokenCreators[i],
                     // we cast this to 16-bit to make it readable in decimal
                     // (var args default to 'int' which is 16-bit on xap)
                     // there should be no token who's size is greater than 65k
                     (uint16_t)(arraySize * (1 + size)));
                     //The '1 +' is for the initial info word in each token.

    //Install the indexed token ptrCache redirection value.  If a token is
    //indexed, set the ptrCache equal to the index number of where the
    //actual token addresses start in the ptrCache.
    if(arraySize != 1) {
      ptrCache[i] = indexSkip;
      indexSkip += arraySize;
    }
  }

  // Again, we force 32-bit into 16-bit for printing purposes.  The var args
  // default to 'int' which is 16-bit on the xap.  We should never exceed
  // 65k words for any of these values, so we are okay.
  emberDebugPrintf("SimEE data: %d words of %d max, tokenCount: %d\n",
                   (uint16_t)*totalTokenStorage,
                   (uint16_t)(SIMEE_BTS_SIZE_B/2),
                   (uint16_t)TOKEN_COUNT);

  //To protect against possible accidental downgrades, check for SimEE2.
  checkForSimEe2();
  
  return halInternalSimEeStartupCore(forceRebuildAll, lookupCache);
}
