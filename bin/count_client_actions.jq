include "countutils";
counter( inputs | fromjson? | {client: .client, action: .action} )
