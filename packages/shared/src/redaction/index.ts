const REDACTED = '[REDACTED]';

const PII_PATTERNS: Record<string, RegExp> = {
  email: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g,
  phone: /\b(\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b/g,
  ssn: /\b\d{3}-\d{2}-\d{4}\b/g,
  creditCard: /\b(?:\d{4}[-\s]?){3}\d{4}\b/g,
  apiKey: /\b(sk-[a-zA-Z0-9]{32,}|[a-zA-Z0-9]{32,})\b/g,
};

const SENSITIVE_FIELD_PATTERNS = [
  /password/i,
  /secret/i,
  /token/i,
  /apiKey/i,
  /api_key/i,
  /authorization/i,
  /credential/i,
  /private/i,
];

export interface RedactionOptions {
  redactPII?: boolean;
  redactSensitiveFields?: boolean;
  sensitiveFieldNames?: string[];
  customPatterns?: Record<string, RegExp>;
}

export function redactString(
  value: string,
  options: RedactionOptions = {}
): string {
  const { redactPII = true, customPatterns = {} } = options;

  if (!redactPII) {
    return value;
  }

  let result = value;

  const allPatterns = { ...PII_PATTERNS, ...customPatterns };

  for (const pattern of Object.values(allPatterns)) {
    result = result.replace(pattern, REDACTED);
  }

  return result;
}

export function redactObject<T extends Record<string, unknown>>(
  obj: T,
  options: RedactionOptions = {}
): T {
  const {
    redactPII = true,
    redactSensitiveFields = true,
    sensitiveFieldNames = [],
  } = options;

  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(obj)) {
    const isSensitive =
      redactSensitiveFields &&
      (SENSITIVE_FIELD_PATTERNS.some((pattern) => pattern.test(key)) ||
        sensitiveFieldNames.includes(key));

    if (isSensitive) {
      result[key] = REDACTED;
    } else if (typeof value === 'string') {
      result[key] = redactPII ? redactString(value, options) : value;
    } else if (Array.isArray(value)) {
      result[key] = value.map((item) =>
        typeof item === 'object' && item !== null
          ? redactObject(item as Record<string, unknown>, options)
          : typeof item === 'string' && redactPII
            ? redactString(item, options)
            : item
      );
    } else if (typeof value === 'object' && value !== null) {
      result[key] = redactObject(value as Record<string, unknown>, options);
    } else {
      result[key] = value;
    }
  }

  return result as T;
}

export function createSafeLogger(
  logger: { info: (...args: unknown[]) => void; error: (...args: unknown[]) => void },
  options: RedactionOptions = {}
): typeof logger {
  const safeLog = (
    method: (...args: unknown[]) => void
  ): ((...args: unknown[]) => void) => {
    return (...args: unknown[]) => {
      const redactedArgs = args.map((arg) => {
        if (typeof arg === 'string') {
          return redactString(arg, options);
        }
        if (typeof arg === 'object' && arg !== null) {
          return redactObject(arg as Record<string, unknown>, options);
        }
        return arg;
      });
      method(...redactedArgs);
    };
  };

  return {
    info: safeLog(logger.info.bind(logger)),
    error: safeLog(logger.error.bind(logger)),
  };
}
