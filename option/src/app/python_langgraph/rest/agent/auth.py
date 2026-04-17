from langgraph_sdk import Auth
import aiohttp
import os
import pprint
from aiocache import cached, SimpleMemoryCache

# See https://docs.langchain.com/langsmith/auth
auth = Auth()

@cached(cache=SimpleMemoryCache, ttl=3600)
async def get_username_from_auth_header(auth_header):
    headers = {'Authorization': auth_header}
    print(auth_header, flush=True)
    try:
        IDCS_URL = os.getenv("IDCS_URL")
        userinfo_url = f"{IDCS_URL}oauth2/v1/userinfo"
        print(userinfo_url, flush=True)
        async with aiohttp.ClientSession() as session:
            async with session.get(userinfo_url, headers=headers) as response:
                pprint.pprint(response)
                response.raise_for_status()
                data = await response.json()
                username = data.get("sub")
                print(f"<get_username_from_auth_header> username={username}", flush=True)
                return username
    except Exception as e:
        print( f"<get_username_from_auth_header> Exception={e}", flush=True )
        raise Auth.exceptions.HTTPException(
            status_code=401,
            detail="Invalid JWT Token"
        )

# Authenticate
@auth.authenticate
async def get_current_user(authorization: str | None) -> Auth.types.MinimalUserDict:
    """Validate JWT tokens and extract user information."""
    print( f"authorization={authorization}", flush=True )
    assert authorization
    scheme, token = authorization.split()
    print( f"<get_current_user> scheme={scheme} token={token}", flush=True )
    # Validate with your auth provider
    if scheme=="Bearer":
        print( f"<get_current_user> before get_username_from_auth_header", flush=True )
        token = await get_username_from_auth_header( authorization )
        print( f"<get_current_user> token", flush=True )
    elif scheme!="User":
        raise Auth.exceptions.HTTPException(
            status_code=401,
            detail="Access Denied"
        )
    return {
        "identity": token,
        "auth_header": authorization,
        "email": "spam@oracle.com",
        "is_authenticated": True
    }
    
# Access only your own threads    
# @auth.on
# async def owner_only(ctx: Auth.types.AuthContext, value: dict):
#     metadata = value.setdefault("metadata", {})
#     metadata["owner"] = ctx.user.identity
#     return {"owner": ctx.user.identity}
