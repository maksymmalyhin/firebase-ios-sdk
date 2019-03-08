/*
 * Copyright 2018 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GULLogger.h"

#import "GDTAssert.h"

/** The console logger prefix. */
static GULLoggerService kGDTConsoleLogger = @"[GoogleDataTransport]";

/** A list of message codes to print in the logger that help to correspond printed messages with
 * code locations.
 *
 * Prefixes:
 * - MCW => MessageCodeWarning
 * - MCE => MessageCodeError
 */
typedef NS_ENUM(NSInteger, GDTMessageCode) {

  /** For warning messages concerning transportBytes: not being implemented by a data object. */
  GDTMCWDataObjectMissingBytesImpl = 1,

  /** For warning messages concerning a failed event upload. */
  GDTMCWUploadFailed = 2,

  /** For warning messages concerning a forced event upload. */
  GDTMCWForcedUpload = 3,

  /** For error messages concerning transform: not being implemented by an event transformer. */
  GDTMCETransformerDoesntImplementTransform = 1000,

  /** For error messages concerning the creation of a directory failing. */
  GDTMCEDirectoryCreationError = 1001,

  /** For error messages concerning the writing of a event file. */
  GDTMCEFileWriteError = 1002
};

/** */
FOUNDATION_EXTERN NSString *_Nonnull GDTMessageCodeEnumToString(GDTMessageCode code);

/** Logs the warningMessage string to the console at the warning level.
 *
 * @param warningMessageFormat The format string to log to the console.
 */
FOUNDATION_EXTERN void GDTLogWarning(GDTMessageCode messageCode,
                                     NSString *_Nonnull warningMessageFormat,
                                     ...) NS_FORMAT_FUNCTION(2, 3);

// A define to wrap GULLogWarning with slightly more convenient usage.
#define GDTLogWarning(MESSAGE_CODE, MESSAGE_FORMAT, ...)                                          \
  GULLogWarning(kGDTConsoleLogger, YES, GDTMessageCodeEnumToString(MESSAGE_CODE), MESSAGE_FORMAT, \
                __VA_ARGS__);

// A define to wrap GULLogError with slightly more convenient usage and a failing assert.
#define GDTLogError(MESSAGE_CODE, MESSAGE_FORMAT, ...)                                          \
  GULLogError(kGDTConsoleLogger, YES, GDTMessageCodeEnumToString(MESSAGE_CODE), MESSAGE_FORMAT, \
              __VA_ARGS__);                                                                     \
  GDTAssert(NO, MESSAGE_FORMAT, __VA_ARGS__);