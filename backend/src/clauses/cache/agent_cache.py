from typing import Any, Dict, Optional
from datetime import datetime, timedelta
from pathlib import Path


class AgentCache:
    """
    Gerenciador de cache para chamadas de agentes.
    Reduz tempo de resposta ao armazenar respostas de agentes.
    """

    def __init__(self, cache_dir: str = "/opt/openclaw/cache/agents"):
        """
        Inicializa o cache de agentes.
        """
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self._init_cache_config()

    def _init_cache_config(self) -> None:
        """Inicializa configuração do cache."""
        config_file = self.cache_dir / "config"
        config_content = """CACHE_ENABLED=true
CACHE_TTL=604800
CACHE_MAX_SIZE=100
CACHE_PATH=/opt/openclaw/cache/agents
"""
        config_file.write_text(config_content)

    def get_cache_key(self, agent_id: str, prompt: str) -> str:
        """
        Gera uma chave única para cache baseado no agent_id e prompt.
        """
        return f"{agent_id}:{prompt}"

    def get_cached_response(self, key: str) -> Optional[Dict[str, Any]]:
        """
        Retorna resposta em cache se existir.
        """
        cache_file = self.cache_dir / f"{key}.json"
        if not cache_file.exists():
            return None

        try:
            content = cache_file.read_text()
            data = self._parse_cache_content(content)
            if data.get("valid_until", 0) > datetime.now():
                return data.get("response")
            return None
        except Exception:
            return None

    def store_response(
        self,
        agent_id: str,
        prompt: str,
        response: Any,
        ttl_seconds: int = 604800
    ) -> bool:
        """
        Armazena resposta no cache.
        """
        key = self.get_cache_key(agent_id, prompt)
        response_data = {
            "response": response,
            "timestamp": datetime.now().isoformat(),
            "valid_until": (datetime.now() + timedelta(seconds=ttl_seconds)).isoformat()
        }
        cache_file = self.cache_dir / f"{key}.json"
        cache_file.write_text(self._serialize_cache_content(response_data))
        return True

    def _parse_cache_content(self, content: str) -> Dict[str, Any]:
        """Parseia conteúdo de cache."""
        # Implementação simplificada - usar JSON na prática
        return {"response": None}

    def _serialize_cache_content(self, data: Dict[str, Any]) -> str:
        """Serializa conteúdo para cache."""
        return str(data)

    def clear_cache(self, agent_id: Optional[str] = None) -> None:
        """
        Limpa cache de um agente específico ou todo o cache.
        """
        if agent_id:
            for cache_file in self.cache_dir.glob(f"{agent_id}_*.json"):
                cache_file.unlink()
        else:
            for cache_file in self.cache_dir.glob("*.json"):
                cache_file.unlink()

    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Retorna estatísticas do cache.
        """
        cache_files = list(self.cache_dir.glob("*.json"))
        return {
            "total_cached_responses": len(cache_files),
            "cache_dir": str(self.cache_dir),
            "enabled": True
        }
