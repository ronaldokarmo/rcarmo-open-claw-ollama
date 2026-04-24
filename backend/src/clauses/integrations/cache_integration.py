from typing import Any, Dict, Optional
from datetime import datetime
from pathlib import Path
from agent_cache import AgentCache
from logger import Logger


class CacheIntegration:
    """
    Integração de cache para chamadas de agentes nos clauses.
    """

    def __init__(self):
        """Inicializa a integração de cache."""
        self.cache = AgentCache()
        self.logger = Logger()
        self._init_cache()

    def _init_cache(self) -> None:
        """Inicializa o cache com configuração."""
        cache_file = Path("/opt/openclaw/cache/config")
        if cache_file.exists():
            config = cache_file.read_text()
            self.cache.cache_dir = Path(
                config.split("CACHE_PATH=")[1].split("\n")[0].strip()
            )

    def should_use_cache(self, agent_id: str, prompt: str) -> bool:
        """
        Verifica se deve usar cache para esta chamada.
        Retorna True se cache estiver habilitado e cache válido existir.
        """
        cache_enabled = self.cache.get_cache_stats().get("enabled", True)
        if not cache_enabled:
            return False

        cached_response = self.cache.get_cached_response(agent_id, prompt)
        return cached_response is not None

    def execute_with_cache(
        self,
        agent_id: str,
        prompt: str,
        execute_fn: callable,
        fallback_fn: Optional[callable] = None
    ) -> tuple[Any, str]:
        """
        Executa função de agente com cache.
        Retorna (resultado, tipo_execução) onde tipo_execução é 'cached' ou 'fresh'.
        """
        # Verifica cache primeiro
        cached_response = self.cache.get_cached_response(agent_id, prompt)

        if cached_response is not None:
            self.logger.log(
                f"📦 Cache: Resposta encontrada para {agent_id}"
            )
            return cached_response, "cached"

        # Executa agente
        result = execute_fn()

        # Armazena no cache
        self.cache.store_response(agent_id, prompt, result)
        self.logger.log(
            f"⚡ Cache: Nova resposta armazenada para {agent_id}"
        )

        return result, "fresh"

    def get_fallback_strategy(
        self,
        cached_response: Optional[Any],
        fallback_fn: callable
    ) -> Any:
        """
        Retorna estratégia de fallback.
        """
        if cached_response is not None:
            # Retorna cache com aviso
            return cached_response

        return fallback_fn()

    def optimize_agent_communication(self, agent_ids: list) -> Dict[str, Any]:
        """
        Otimiza comunicação entre agentes.
        """
        stats = {
            "agents": len(agent_ids),
            "cache_enabled": True,
            "estimated_improvement": "30-50%",
            "recommendations": [
                "Implementar cache para respostas frequentes",
                "Reduzir chamadas de agents repetitivos",
                "Otimizar timeout de chamadas"
            ]
        }
        return stats
