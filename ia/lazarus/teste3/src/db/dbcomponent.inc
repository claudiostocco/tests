{$ifdef FPC}
  {$define USE_SQLDB}
  {$define USE_ZEOS}
  {$define USE_UNIDAC}
  {define DEFAULT_ZEOS}
  {define DEFAULT_SQLDB}
  {$define DEFAULT_UNIDAC}
{$else}
  {$define USE_FIREDAC}
{$endif}

